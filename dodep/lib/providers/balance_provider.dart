import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';

class BalanceProvider with ChangeNotifier, WidgetsBindingObserver {
  int _balance = 3000; // Начальный баланс
  static const String _balanceKeyPrefix = 'balance_';
  static const String _localUpdateFlagKey = 'has_local_balance_update';
  late final AuthService _authService;
  bool _isInitialized = false;
  bool _justSynced = false;
  bool _ignoreRemoteBalanceUpdate = false;
  bool _pendingSyncAfterAuth = false;
  bool _isWaitingForAuthInit = false;
  bool _hasUnsyncedLocalChanges = false;
  bool _isSyncingBalance = false;

  // --- Добавлено для отслеживания подключения ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  BalanceProvider() {
    // Инициализация будет происходить через ChangeNotifierProxyProvider
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        if (_hasUnsyncedLocalChanges) {
          debugPrint('[BalanceProvider] Интернет появился, есть несинхронизированные изменения, пушим локальный баланс в Firestore');
          syncLocalBalanceToServer();
        } else {
          debugPrint('[BalanceProvider] Интернет появился, но нет несинхронизированных изменений, sync не нужен');
        }
      }
      _wasOffline = result == ConnectivityResult.none;
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void updateAuthService(AuthService authService) {
    if (!_isInitialized) {
      _authService = authService;
      _initBalance();
    }
  }

  int get balance => _balance;

  String get _currentBalanceKey {
    final currentUser = _authService.getCurrentUserSync();
    return '${_balanceKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  String get _hiveBalanceKey {
    final currentUser = _authService.getCurrentUserSync();
    return 'balance_${currentUser?.username ?? 'guest'}';
  }

  /// Миграция баланса из SharedPreferences в Hive (один раз при первом запуске)
  Future<void> _migratePrefsToHiveIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final box = Hive.box<int>('balances');
    final key = _currentBalanceKey;
    final hiveKey = _hiveBalanceKey;
    if (prefs.containsKey(key) && !box.containsKey(hiveKey)) {
      final oldBalance = prefs.getInt(key);
      if (oldBalance != null) {
        await box.put(hiveKey, oldBalance);
        debugPrint('[BalanceProvider] Миграция: скопирован баланс $oldBalance из SharedPreferences в Hive ($hiveKey)');
      }
    }
  }

  Future<void> _initBalance() async {
    if (_isInitialized) return;
    try {
      debugPrint('Инициализация BalanceProvider');
      _authService.addListener(_onAuthStateChanged);
      await _migratePrefsToHiveIfNeeded();
      final box = Hive.box<int>('balances');
      final hiveKey = _hiveBalanceKey;
      if (box.containsKey(hiveKey)) {
        _balance = box.get(hiveKey)!;
        debugPrint('[BalanceProvider] Баланс инициализирован из Hive: $_balance');
      } else {
        _balance = 3000;
        await box.put(hiveKey, _balance);
        debugPrint('[BalanceProvider] Баланс по умолчанию (Hive): $_balance');
      }
      notifyListeners();
      _isInitialized = true;
      debugPrint('BalanceProvider инициализирован');
    } catch (e) {
      debugPrint('Ошибка при инициализации баланса: $e');
      _isInitialized = false;
    }
  }

  void _onAuthStateChanged() async {
    debugPrint('Обнаружено изменение в AuthService');
    if (_justSynced) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: игнорируем обновление из Firebase, т.к. только что был sync (локальный баланс главный)');
      notifyListeners();
      return;
    }
    if ((_pendingSyncAfterAuth || _isWaitingForAuthInit) && _authService.getCurrentUserSync() != null) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: был отложенный sync после авторизации/инициализации, пушим локальный баланс');
      await syncLocalBalanceToServer();
      _pendingSyncAfterAuth = false;
      _isWaitingForAuthInit = false;
      return;
    }
    if (_justSynced) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: только что был sync, игнорируем обновление из Firebase');
      notifyListeners();
      return;
    }
    final didSync = await syncLocalBalanceIfNeeded();
    if (didSync) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: был sync, оставляем локальный баланс: \x1b[33m${_balance}\x1b[0m');
      notifyListeners();
      return;
    }
    debugPrint('[BalanceProvider] _onAuthStateChanged: sync не был нужен, вызываем _syncOrLoadBalance');
    await _syncOrLoadBalance();
  }

  Future<void> _syncOrLoadBalance() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] _syncOrLoadBalance: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] _syncOrLoadBalance: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    final box = Hive.box<int>('balances');
    final hasLocalUpdate = box.containsKey(_hiveBalanceKey);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Нет интернета — всегда грузим локальный баланс
      _balance = box.get(_hiveBalanceKey) ?? 3000;
      debugPrint('[BalanceProvider] _syncOrLoadBalance: Нет интернета, загружаем баланс только из Hive: $_balance');
      notifyListeners();
      return;
    }
    if (hasLocalUpdate && connectivityResult != ConnectivityResult.none) {
      debugPrint('[BalanceProvider] _syncOrLoadBalance: Синхронизируем локальный баланс с сервером');
      await syncLocalBalanceToServer();
      await box.put(_hiveBalanceKey, _balance);
      // НЕ вызываем _forceLoadBalance, чтобы не перезаписать локальный баланс!
      // Просто оставляем локальный баланс, он уже синхронизирован
      return;
    } else {
      debugPrint('[BalanceProvider] _syncOrLoadBalance: Нет локальных изменений, вызываем _forceLoadBalance (будет загружено из Firestore)');
      await _forceLoadBalance();
    }
  }

  /// Всегда пушит локальный баланс в Firestore и блокирует загрузку баланса из Firestore на 5 секунд
  Future<void> syncLocalBalanceToServer() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: только что был sync, пропускаем');
      return;
    }
    if (!_hasUnsyncedLocalChanges) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: нет несинхронизированных изменений, sync не нужен');
      return;
    }
    _isSyncingBalance = true;
    try {
      final box = Hive.box<int>('balances');
      final localBalance = box.get(_hiveBalanceKey) ?? _balance;
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        try {
          debugPrint('[BalanceProvider] syncLocalBalanceToServer: ПУШИМ в Firebase локальный баланс из Hive: $localBalance');
          await _authService.updateBalance(localBalance);
          debugPrint('[BalanceProvider] syncLocalBalanceToServer: updateBalance завершён');
          _authService.setCurrentUserBalance(localBalance);
          _balance = localBalance;
          debugPrint('[BalanceProvider] syncLocalBalanceToServer: Локальный баланс синхронизирован с сервером: $_balance');
          _ignoreRemoteBalanceUpdate = true;
          _justSynced = true;
          _hasUnsyncedLocalChanges = false;
          // После sync баланса — пушим все остальные данные пользователя с актуальным балансом
          await _authService.saveUserDataToFirestore();
          Future.delayed(const Duration(seconds: 5), () {
            if (_ignoreRemoteBalanceUpdate) {
              _ignoreRemoteBalanceUpdate = false;
              debugPrint('[BalanceProvider] syncLocalBalanceToServer: _ignoreRemoteBalanceUpdate снят');
            }
            _justSynced = false;
            debugPrint('[BalanceProvider] syncLocalBalanceToServer: _justSynced снят');
          });
          notifyListeners();
          _pendingSyncAfterAuth = false;
          _isWaitingForAuthInit = false;
        } catch (e) {
          debugPrint('Ошибка при синхронизации баланса: $e');
        }
      } else {
        debugPrint('[BalanceProvider] syncLocalBalanceToServer: пользователь не авторизован, sync будет выполнен после авторизации');
        _pendingSyncAfterAuth = true;
        _isWaitingForAuthInit = true;
      }
    } finally {
      _isSyncingBalance = false;
    }
  }

  Future<void> _forceLoadBalance() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] _forceLoadBalance: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] _forceLoadBalance: игнорируем обновление из Firebase, т.к. только что был sync (локальный баланс главный)');
      final box = Hive.box<int>('balances');
      await box.put(_hiveBalanceKey, _balance);
      notifyListeners();
      return;
    }
    try {
      final box = Hive.box<int>('balances');
      final hasLocalUpdate = box.containsKey(_hiveBalanceKey);
      if (hasLocalUpdate) {
        debugPrint('[BalanceProvider] _forceLoadBalance: Есть несинхронизированные изменения, не перезаписываем локальный баланс');
        _balance = box.get(_hiveBalanceKey) ?? 3000;
        notifyListeners();
        return;
      }
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('[BalanceProvider] _forceLoadBalance: Принудительная загрузка баланса из Firestore для пользователя: ${currentUser.username}');
        _balance = currentUser.balance;
        debugPrint('[BalanceProvider] _forceLoadBalance: Баланс из Firestore: $_balance');
        await box.put(_hiveBalanceKey, _balance);
        notifyListeners();
        debugPrint('[BalanceProvider] _forceLoadBalance: Баланс успешно обновлен и сохранен');
      } else {
        debugPrint('[BalanceProvider] _forceLoadBalance: Пользователь не авторизован, установка гостевого баланса');
        _balance = 3000;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при принудительной загрузке баланса: $e');
      _balance = 3000;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] initialize: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] initialize: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final box = Hive.box<int>('balances');
      _balance = box.get(_hiveBalanceKey) ?? 3000;
      debugPrint('Нет интернета, инициализация баланса только из Hive: $_balance');
      notifyListeners();
      return;
    }
    if (!_isInitialized) {
      await _initBalance();
    } else {
      await _forceLoadBalance();
    }
  }

  Future<void> _loadBalance() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] _loadBalance: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] _loadBalance: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    try {
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('[BalanceProvider] _loadBalance: Загрузка баланса из Firestore для пользователя: ${currentUser.username}');
        // Очищаем старый баланс
        final box = Hive.box<int>('balances');
        await box.delete(_hiveBalanceKey);
        // Загружаем баланс из AuthService
        _balance = currentUser.balance;
        debugPrint('[BalanceProvider] _loadBalance: Баланс из Firestore: $_balance');
        // Сохраняем локально
        await box.put(_hiveBalanceKey, _balance);
      } else {
        debugPrint('[BalanceProvider] _loadBalance: Пользователь не авторизован, загрузка гостевого баланса');
        final box = Hive.box<int>('balances');
        _balance = box.get(_hiveBalanceKey) ?? 3000;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке баланса: $e');
      _balance = 3000;
      notifyListeners();
    }
  }

  /// Надежно сохраняет баланс в Hive с верификацией (до 3 попыток)
  Future<void> _setAndVerifyBalance(int value) async {
    final box = Hive.box<int>('balances');
    final hiveKey = _hiveBalanceKey;
    int attempts = 0;
    bool success = false;
    while (attempts < 3 && !success) {
      await box.put(hiveKey, value);
      final readBack = box.get(hiveKey);
      if (readBack == value) {
        debugPrint('[BalanceProvider][Hive] _setAndVerifyBalance: успешно сохранено $value (попытка ${attempts + 1})');
        success = true;
      } else {
        debugPrint('[BalanceProvider][Hive] _setAndVerifyBalance: не совпало! Ожидалось $value, прочитано $readBack (попытка ${attempts + 1})');
        attempts++;
      }
    }
    if (!success) {
      debugPrint('[BalanceProvider][Hive] _setAndVerifyBalance: НЕ УДАЛОСЬ сохранить баланс $value после 3 попыток!');
    }
  }

  Future<void> _saveBalance() async {
    try {
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('Сохранение баланса для пользователя: \x1b[36m${currentUser.username}\x1b[0m');
        final connectivityResult = await Connectivity().checkConnectivity();
        // СНАЧАЛА сохраняем баланс локально (Hive)
        await _setAndVerifyBalance(_balance);
        if (connectivityResult != ConnectivityResult.none) {
          // ЕСЛИ есть интернет, пушим на сервер и сбрасываем флаг
        await _authService.updateBalance(_balance);
        } else {
          debugPrint('Нет интернета, сохраняем баланс только локально (Hive)');
        }
        debugPrint('Баланс сохранен локально (Hive): $_balance');
      } else {
        debugPrint('Пользователь не авторизован, сохранение локального баланса (Hive)');
        await _setAndVerifyBalance(_balance);
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении баланса: $e');
      rethrow;
    }
  }

  Future<void> addBalance(int amount) async {
    if (amount <= 0) return;
    final oldBalance = _balance;
    _balance += amount;
    notifyListeners(); // Сразу обновляем UI
    try {
      await _saveBalance();
      debugPrint('Баланс увеличен: $oldBalance -> $_balance');
      _hasUnsyncedLocalChanges = true;
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        debugPrint('[BalanceProvider] addBalance: есть интернет, пушим sync');
        syncLocalBalanceToServer();
      }
    } catch (e) {
      _balance = oldBalance;
      notifyListeners();
      debugPrint('Ошибка при увеличении баланса: $e');
      rethrow;
    }
  }

  Future<void> subtractBalance(int amount) async {
    if (amount <= 0 || _balance < amount) return;
    final oldBalance = _balance;
    _balance -= amount;
    notifyListeners(); // Сразу обновляем UI
    try {
      await _saveBalance();
      debugPrint('Баланс уменьшен: $oldBalance -> $_balance');
      _hasUnsyncedLocalChanges = true;
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        debugPrint('[BalanceProvider] subtractBalance: есть интернет, пушим sync');
        syncLocalBalanceToServer();
      }
    } catch (e) {
      _balance = oldBalance;
      notifyListeners();
      debugPrint('Ошибка при уменьшении баланса: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(int amount) async {
    if (amount > 0) {
      await addBalance(amount);
    } else {
      await subtractBalance(-amount);
    }
    // syncLocalBalanceToServer уже вызывается внутри add/subtract
  }

  Future<void> updateBalanceForUser() async {
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] updateBalanceForUser: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    debugPrint('[BalanceProvider] updateBalanceForUser: Принудительное обновление баланса для пользователя');
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Нет интернета — всегда грузим локальный баланс
      final box = Hive.box<int>('balances');
      _balance = box.get(_hiveBalanceKey) ?? 3000;
      debugPrint('[BalanceProvider] updateBalanceForUser: Нет интернета, загружаем баланс только из Hive: $_balance');
      notifyListeners();
    } else {
      debugPrint('[BalanceProvider] updateBalanceForUser: Есть интернет, вызываем _forceLoadBalance (будет загружено из Firestore)');
      await _forceLoadBalance();
    }
  }

  /// Синхронизирует локальный баланс с сервером, если есть несинхронизированные изменения и есть интернет.
  /// Возвращает true, если была синхронизация, иначе false.
  /// (Теперь не используется для автоматической sync, sync всегда происходит при появлении интернета)
  Future<bool> syncLocalBalanceIfNeeded() async {
    // Оставлено для совместимости, но всегда возвращает false
    return false;
  }

  Future<void> initializeSmart() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] initializeSmart: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] initializeSmart: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    final box = Hive.box<int>('balances');
    final hasLocalUpdate = box.containsKey(_hiveBalanceKey);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _balance = box.get(_hiveBalanceKey) ?? 3000;
      debugPrint('Нет интернета, smart init баланса только из Hive: $_balance');
      notifyListeners();
      return;
    }
    if (hasLocalUpdate && connectivityResult != ConnectivityResult.none) {
      debugPrint('Syncing local balance to server (smart init)...');
      await syncLocalBalanceToServer();
      await box.put(_hiveBalanceKey, _balance);
      final localBalance = box.get(_hiveBalanceKey);
      if (localBalance != null) {
        _balance = localBalance;
        notifyListeners();
      }
    } else {
      await initialize();
    }
  }

  /// Если есть локальные изменения — только синхронизирует их с сервером и оставляет локальный баланс.
  /// Если нет — грузит баланс с сервера.
  Future<void> syncLocalOrLoadRemoteBalance() async {
    if (_justSynced) {
      debugPrint('[BalanceProvider] syncLocalOrLoadRemoteBalance: только что был sync, пропускаем');
      return;
    }
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] syncLocalOrLoadRemoteBalance: игнорируем sync/load, т.к. только что был sync (локальный баланс главный)');
      return;
    }
    final box = Hive.box<int>('balances');
    final hasLocalUpdate = box.containsKey(_hiveBalanceKey);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _balance = box.get(_hiveBalanceKey) ?? 3000;
      debugPrint('Нет интернета, syncLocalOrLoadRemoteBalance: только локальный баланс: $_balance');
      notifyListeners();
      return;
    }
    if (hasLocalUpdate) {
      debugPrint('syncLocalOrLoadRemoteBalance: есть локальные изменения, только синхронизируем');
      await syncLocalBalanceToServer();
      await box.put(_hiveBalanceKey, _balance);
      // НЕ грузим с сервера!
      return;
    } else {
      debugPrint('syncLocalOrLoadRemoteBalance: локальных изменений нет, грузим с сервера');
    await _forceLoadBalance();
    }
  }

  bool get ignoreRemoteBalanceUpdate => _ignoreRemoteBalanceUpdate;

  bool get justSynced => _justSynced;

  bool get isSyncingBalance => _isSyncingBalance;

  @override
  void dispose() {
    if (_isInitialized) {
      _authService.removeListener(_onAuthStateChanged);
    }
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        debugPrint('[BalanceProvider] AppLifecycleState.resumed: проверяем sync');
        syncLocalBalanceToServer();
      }
    }
  }
} 