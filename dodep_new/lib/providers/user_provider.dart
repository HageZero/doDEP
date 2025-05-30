import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/sync_service.dart';

class UserProvider with ChangeNotifier {
  final SyncService _syncService = SyncService();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> createUser(UserModel user) async {
    await _syncService.syncUserData(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadUser(String userId) async {
    _currentUser = await _syncService.getUserData(userId);
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await _syncService.updateUserData(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    await _syncService.deleteUserData(userId);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateBalance(double newBalance) async {
    if (_currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: _currentUser!.password,
        balance: newBalance,
        purchasedStyles: _currentUser!.purchasedStyles,
        avatarUrl: _currentUser!.avatarUrl,
        totalWinnings: _currentUser!.totalWinnings,
        spinsCount: _currentUser!.spinsCount,
        maxWin: _currentUser!.maxWin,
      );
      await updateUser(updatedUser);
    }
  }

  Future<void> addPurchasedStyle(String styleId) async {
    if (_currentUser != null) {
      final updatedStyles = List<String>.from(_currentUser!.purchasedStyles)
        ..add(styleId);
      final updatedUser = UserModel(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: _currentUser!.password,
        balance: _currentUser!.balance,
        purchasedStyles: updatedStyles,
        avatarUrl: _currentUser!.avatarUrl,
        totalWinnings: _currentUser!.totalWinnings,
        spinsCount: _currentUser!.spinsCount,
        maxWin: _currentUser!.maxWin,
      );
      await updateUser(updatedUser);
    }
  }

  Future<void> updateStats({
    double? totalWinnings,
    int? spinsCount,
    double? maxWin,
  }) async {
    if (_currentUser != null) {
      final updatedUser = UserModel(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password: _currentUser!.password,
        balance: _currentUser!.balance,
        purchasedStyles: _currentUser!.purchasedStyles,
        avatarUrl: _currentUser!.avatarUrl,
        totalWinnings: totalWinnings ?? _currentUser!.totalWinnings,
        spinsCount: spinsCount ?? _currentUser!.spinsCount,
        maxWin: maxWin ?? _currentUser!.maxWin,
      );
      await updateUser(updatedUser);
    }
  }
} 