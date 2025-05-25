import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BalanceProvider with ChangeNotifier {
  int _balance = 3000; // Начальный баланс
  static const String _balanceKey = 'balance';

  BalanceProvider() {
    _loadBalance();
  }

  int get balance => _balance;

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt(_balanceKey) ?? 3000;
    notifyListeners();
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_balanceKey, _balance);
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
} 