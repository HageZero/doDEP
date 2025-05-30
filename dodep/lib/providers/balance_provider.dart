import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class BalanceProvider with ChangeNotifier {
  int _balance = 3000; // Начальный баланс
  static const String _balanceKeyPrefix = 'balance_';
  late final AuthService _authService;
  bool _isInitialized = false;

  BalanceProvider() {
    // Инициализация будет происходить через ChangeNotifierProxyProvider
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

  Future<void> _initBalance() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('Инициализация BalanceProvider');
      
      // Слушаем изменения в AuthService
      _authService.addListener(_onAuthStateChanged);
      
      // Принудительно загружаем начальный баланс
      await _forceLoadBalance();
      
      _isInitialized = true;
      debugPrint('BalanceProvider инициализирован');
    } catch (e) {
      debugPrint('Ошибка при инициализации баланса: $e');
      _isInitialized = false;
    }
  }

  void _onAuthStateChanged() {
    debugPrint('Обнаружено изменение в AuthService');
    _forceLoadBalance();
  }

  Future<void> _forceLoadBalance() async {
    try {
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('Принудительная загрузка баланса для пользователя: ${currentUser.username}');
        
        // Очищаем старый баланс
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentBalanceKey);
        
        // Устанавливаем новый баланс напрямую из AuthService
        _balance = currentUser.balance;
        debugPrint('Установлен новый баланс: $_balance');
        
        // Сохраняем локально
        await prefs.setInt(_currentBalanceKey, _balance);
        
        // Уведомляем слушателей
        notifyListeners();
        debugPrint('Баланс успешно обновлен и сохранен');
      } else {
        debugPrint('Пользователь не авторизован, установка гостевого баланса');
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
    if (!_isInitialized) {
      await _initBalance();
    } else {
      await _forceLoadBalance();
    }
  }

  Future<void> _loadBalance() async {
    try {
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('Загрузка баланса для пользователя: ${currentUser.username}');
        
        // Очищаем старый баланс
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_currentBalanceKey);
        
        // Загружаем баланс из AuthService
        _balance = currentUser.balance;
        debugPrint('Загружен баланс: $_balance');
        
        // Сохраняем локально
        await prefs.setInt(_currentBalanceKey, _balance);
      } else {
        debugPrint('Пользователь не авторизован, загрузка гостевого баланса');
        final prefs = await SharedPreferences.getInstance();
        _balance = prefs.getInt(_currentBalanceKey) ?? 3000;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке баланса: $e');
      _balance = 3000;
      notifyListeners();
    }
  }

  Future<void> _saveBalance() async {
    try {
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser != null) {
        debugPrint('Сохранение баланса для пользователя: ${currentUser.username}');
        
        // Обновляем в Firebase через AuthService
        await _authService.updateBalance(_balance);
        
        // Сохраняем локально
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_currentBalanceKey, _balance);
        debugPrint('Баланс сохранен: $_balance');
      } else {
        debugPrint('Пользователь не авторизован, сохранение локального баланса');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_currentBalanceKey, _balance);
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
    
    try {
      await _saveBalance();
      notifyListeners();
      debugPrint('Баланс увеличен: $oldBalance -> $_balance');
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
    
    try {
      await _saveBalance();
      notifyListeners();
      debugPrint('Баланс уменьшен: $oldBalance -> $_balance');
    } catch (e) {
      _balance = oldBalance;
      notifyListeners();
      debugPrint('Ошибка при уменьшении баланса: $e');
      rethrow;
    }
  }

  Future<void> resetBalance() async {
    final oldBalance = _balance;
    _balance = 3000;
    
    try {
      await _saveBalance();
      notifyListeners();
      debugPrint('Баланс сброшен: $oldBalance -> $_balance');
    } catch (e) {
      _balance = oldBalance;
      notifyListeners();
      debugPrint('Ошибка при сбросе баланса: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(int amount) async {
    if (amount > 0) {
      await addBalance(amount);
    } else {
      await subtractBalance(-amount);
    }
  }

  Future<void> updateBalanceForUser() async {
    debugPrint('Принудительное обновление баланса для пользователя');
    await _forceLoadBalance();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _authService.removeListener(_onAuthStateChanged);
    }
    super.dispose();
  }
} 