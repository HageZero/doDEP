import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

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
  bool _isOnline = true; // Добавляем поле для отслеживания состояния интернета
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Добавляем экземпляр Firestore

  // --- Добавлено для отслеживания подключения ---
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  // Геттер для текущего пользователя
  AppUser? get _currentUser => _authService.getCurrentUserSync();

  BalanceProvider(AuthService authService) {
    _authService = authService;
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _isOnline = result != ConnectivityResult.none;
      
      if (_isOnline) {
        debugPrint('[BalanceProvider] Интернет появился, проверяем локальные изменения');
        _isSyncingBalance = true;
        
        try {
          final box = Hive.box<int>('balances');
          final localBalance = box.get(_hiveBalanceKey);
          
          if (localBalance != null && localBalance != _balance) {
            _hasUnsyncedLocalChanges = true;
            debugPrint('[BalanceProvider] Интернет появился, обнаружены локальные изменения, баланс: $localBalance');
            _balance = localBalance;
            notifyListeners();
            
            await syncLocalBalanceToServer();
            
            _hasUnsyncedLocalChanges = false;
            _justSynced = true;
            _ignoreRemoteBalanceUpdate = true;
            
            Future.delayed(const Duration(seconds: 5), () {
              _justSynced = false;
              _ignoreRemoteBalanceUpdate = false;
            });
          } else {
            debugPrint('[BalanceProvider] Интернет появился, но нет локальных изменений, загружаем с сервера');
            await _forceLoadBalance();
          }
        } finally {
          _isSyncingBalance = false;
        }
      }
      _wasOffline = !_isOnline;
    });
    WidgetsBinding.instance.addObserver(this);
    _initBalance();
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
      
      // Проверяем наличие локальных изменений
      if (box.containsKey(hiveKey)) {
        final localBalance = box.get(hiveKey)!;
        _balance = localBalance;
        _hasUnsyncedLocalChanges = true;
        debugPrint('[BalanceProvider] Баланс инициализирован из Hive: $_balance (есть локальные изменения)');
        
        // Проверяем интернет
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          debugPrint('[BalanceProvider] Есть интернет при инициализации, синхронизируем локальный баланс');
          await syncLocalBalanceToServer();
        }
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
    if (_isSyncingBalance) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: идет синхронизация, пропускаем');
      return;
    }

    debugPrint('[BalanceProvider] Обнаружено изменение в AuthService');
    
    // Сбрасываем все флаги синхронизации при смене пользователя
    _ignoreRemoteBalanceUpdate = false;
    _justSynced = false;
    
    if (_authService.getCurrentUserSync() != null) {
      debugPrint('[BalanceProvider] _onAuthStateChanged: Загрузка баланса для нового пользователя');
      
      // Проверяем наличие локальных изменений
      final box = Hive.box<int>('balances');
      final localBalance = box.get(_hiveBalanceKey);
      
      // Проверяем интернет
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('[BalanceProvider] _onAuthStateChanged: нет интернета, используем локальный баланс');
        if (localBalance != null) {
          _balance = localBalance;
          _hasUnsyncedLocalChanges = true;
          notifyListeners();
        }
        return;
      }
      
      if (localBalance != null) {
        debugPrint('[BalanceProvider] _onAuthStateChanged: обнаружен локальный баланс: $localBalance');
        _hasUnsyncedLocalChanges = true;
        _balance = localBalance;
        notifyListeners();
        
        // Синхронизируем локальный баланс с сервером
        await syncLocalBalanceToServer();
      } else {
        debugPrint('[BalanceProvider] _onAuthStateChanged: нет локального баланса, загружаем с сервера');
        await _forceLoadBalance();
      }
    } else {
      debugPrint('[BalanceProvider] _onAuthStateChanged: Пользователь не авторизован');
      _balance = 3000;
      notifyListeners();
    }
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
    if (_isSyncingBalance) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: идет синхронизация, пропускаем');
      return;
    }

    // Проверяем интернет перед любыми операциями с Firebase
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: нет интернета, sync отложен');
      _hasUnsyncedLocalChanges = true;
      return;
    }

    if (_currentUser == null) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: нет текущего пользователя');
      return;
    }

    try {
      _isSyncingBalance = true;
      _ignoreRemoteBalanceUpdate = true;

      debugPrint('[BalanceProvider] syncLocalBalanceToServer: начинаем синхронизацию');
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: текущий баланс: $_balance');

      // Обновляем баланс в Firestore
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'balance': _balance,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _hasUnsyncedLocalChanges = false;
      _justSynced = true;
      
      // Устанавливаем таймер для сброса флагов
      Future.delayed(const Duration(seconds: 5), () {
        _isSyncingBalance = false;
        _ignoreRemoteBalanceUpdate = false;
        _justSynced = false;
      });
      
      notifyListeners();
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: баланс успешно синхронизирован');
    } catch (e) {
      debugPrint('[BalanceProvider] syncLocalBalanceToServer: ошибка синхронизации: $e');
      _hasUnsyncedLocalChanges = true;
    } finally {
      _isSyncingBalance = false;
    }
  }

  Future<void> _forceLoadBalance() async {
    if (_isSyncingBalance) {
      debugPrint('[BalanceProvider] _forceLoadBalance: идет синхронизация, пропускаем');
      return;
    }
    
    if (_justSynced) {
      debugPrint('[BalanceProvider] _forceLoadBalance: только что был sync, пропускаем');
      return;
    }
    
    if (_ignoreRemoteBalanceUpdate) {
      debugPrint('[BalanceProvider] _forceLoadBalance: игнорируем обновление из Firebase, т.к. только что был sync (локальный баланс главный)');
      return;
    }

    // Проверяем интернет перед любыми операциями с Firebase
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('[BalanceProvider] _forceLoadBalance: нет интернета, используем локальный баланс');
      final box = Hive.box<int>('balances');
      final localBalance = box.get(_hiveBalanceKey);
      if (localBalance != null) {
        _balance = localBalance;
        _hasUnsyncedLocalChanges = true;
        debugPrint('[BalanceProvider] _forceLoadBalance: установлен локальный баланс: $_balance');
      }
      notifyListeners();
      return;
    }

    try {
      _isSyncingBalance = true;
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('[BalanceProvider] _forceLoadBalance: Загрузка баланса из Firestore для пользователя: ${currentUser.username}');
        
        // Загружаем баланс из Firestore
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final serverBalance = userDoc.data()?['balance'] as int? ?? _balance;
          debugPrint('[BalanceProvider] _forceLoadBalance: Баланс из Firestore: $serverBalance');
          
          // Обновляем локальное состояние
          _balance = serverBalance;
          await _setAndVerifyBalance(_balance);
          notifyListeners();
        }
      } else {
        debugPrint('[BalanceProvider] _forceLoadBalance: Пользователь не авторизован, установка гостевого баланса');
        _balance = 3000;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BalanceProvider] _forceLoadBalance: Ошибка при загрузке баланса: $e');
      // При ошибке используем локальный баланс
      final box = Hive.box<int>('balances');
      final localBalance = box.get(_hiveBalanceKey);
      if (localBalance != null) {
        _balance = localBalance;
        _hasUnsyncedLocalChanges = true;
        debugPrint('[BalanceProvider] _forceLoadBalance: при ошибке установлен локальный баланс: $_balance');
      } else {
        _balance = 3000;
      }
      notifyListeners();
    } finally {
      _isSyncingBalance = false;
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
        
        if (connectivityResult != ConnectivityResult.none) {
          _ignoreRemoteBalanceUpdate = true;
          
          try {
            // Обновляем баланс в Firestore
            await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .update({
              'balance': _balance,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            
            _hasUnsyncedLocalChanges = false;
            _justSynced = true;
            debugPrint('[BalanceProvider] _saveBalance: баланс синхронизирован с сервером');
          } finally {
            // Сбрасываем флаги через 5 секунд
            Future.delayed(const Duration(seconds: 5), () {
              _ignoreRemoteBalanceUpdate = false;
              _justSynced = false;
            });
          }
        } else {
          debugPrint('[BalanceProvider] _saveBalance: нет интернета, сохраняем баланс только локально (Hive)');
          _hasUnsyncedLocalChanges = true;
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

  void addBalance(int amount) {
    if (amount <= 0) return;

    final oldBalance = _balance;
    _balance += amount;
    
    // Сразу сохраняем в Hive
    final box = Hive.box<int>('balances');
    box.put(_hiveBalanceKey, _balance);
    _hasUnsyncedLocalChanges = true;
    
    notifyListeners(); // Обновляем UI
    debugPrint('Баланс увеличен: $oldBalance -> $_balance');
    
    // Асинхронно синхронизируем с сервером если есть интернет
    Future.microtask(() async {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none && !_isSyncingBalance) {
          _isSyncingBalance = true;
          try {
            await _saveBalance();
          } finally {
            _isSyncingBalance = false;
          }
        }
      } catch (e) {
        debugPrint('Ошибка при синхронизации баланса: $e');
      }
    });
  }

  void subtractBalance(int amount) {
    if (amount <= 0 || _balance < amount) return;

    final oldBalance = _balance;
    _balance -= amount;
    
    // Сразу сохраняем в Hive
    final box = Hive.box<int>('balances');
    box.put(_hiveBalanceKey, _balance);
    _hasUnsyncedLocalChanges = true;
    
    notifyListeners(); // Обновляем UI
    debugPrint('Баланс уменьшен: $oldBalance -> $_balance');
    
    // Асинхронно синхронизируем с сервером если есть интернет
    Future.microtask(() async {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none && !_isSyncingBalance) {
          _isSyncingBalance = true;
          try {
            await _saveBalance();
          } finally {
            _isSyncingBalance = false;
          }
        }
      } catch (e) {
        debugPrint('Ошибка при синхронизации баланса: $e');
      }
    });
  }

  void updateBalance(int amount) {
    if (amount > 0) {
      addBalance(amount);
    } else if (amount < 0) {
      subtractBalance(-amount);
    }
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
      debugPrint('[BalanceProvider] AppLifecycleState.resumed: проверяем состояние');
      
      // Проверяем наличие локальных изменений
      final box = Hive.box<int>('balances');
      final localBalance = box.get(_hiveBalanceKey);
      
      if (localBalance != null) {
        debugPrint('[BalanceProvider] AppLifecycleState.resumed: обнаружен локальный баланс: $localBalance');
        _hasUnsyncedLocalChanges = true;
        _balance = localBalance;
        notifyListeners();
        
        // Проверяем интернет
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          debugPrint('[BalanceProvider] AppLifecycleState.resumed: есть интернет, синхронизируем локальный баланс');
          await syncLocalBalanceToServer();
        } else {
          debugPrint('[BalanceProvider] AppLifecycleState.resumed: нет интернета, используем локальный баланс');
        }
      } else {
        debugPrint('[BalanceProvider] AppLifecycleState.resumed: нет локального баланса');
        // Проверяем интернет
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          debugPrint('[BalanceProvider] AppLifecycleState.resumed: есть интернет, загружаем с сервера');
          await _forceLoadBalance();
        }
      }
    }
  }
} 