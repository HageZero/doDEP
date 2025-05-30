import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class BalanceProvider with ChangeNotifier {
  int _balance = 3000; // Начальный баланс
  static const String _balanceKeyPrefix = 'balance_';
  final AuthService _authService = AuthService();

  BalanceProvider() {
    _loadBalance();
  }

  int get balance => _balance;

  String get _currentBalanceKey {
    final currentUser = _authService.getCurrentUserSync();
    return '${_balanceKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  Future<void> initialize() async {
    await _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_currentBalanceKey) ?? 3000;
    notifyListeners();
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentBalanceKey, _balance);
  }

  Future<void> addBalance(int amount) async {
    _balance += amount;
    await _saveBalance();
    notifyListeners();
  }

  Future<void> subtractBalance(int amount) async {
    if (_balance >= amount) {
      _balance -= amount;
      await _saveBalance();
      notifyListeners();
    }
  }

  Future<void> resetBalance() async {
    _balance = 3000;
    await _saveBalance();
    notifyListeners();
  }

  // Для обратной совместимости со старым кодом
  Future<void> updateBalance(int amount) async {
    if (amount > 0) {
      await addBalance(amount);
    } else {
      await subtractBalance(-amount);
    }
  }

  // Метод для обновления баланса при смене пользователя
  Future<void> updateBalanceForUser() async {
    await _loadBalance();
  }
} 