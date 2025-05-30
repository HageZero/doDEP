import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'sync_service.dart';
import 'package:uuid/uuid.dart';

class AuthService extends ChangeNotifier {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';
  static const String _avatarKeyPrefix = 'avatar_';
  User? _currentUser;
  final SyncService _syncService = SyncService();
  final _uuid = Uuid();

  AuthService() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  User? getCurrentUserSync() {
    return _currentUser;
  }

  String get _currentAvatarKey {
    final currentUser = getCurrentUserSync();
    return '${_avatarKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  Future<String?> getCurrentUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentAvatarKey);
  }

  Future<void> setCurrentUserAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentAvatarKey, avatarPath);
    notifyListeners();
  }

  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    
    // Проверяем, существует ли пользователь
    for (var userJson in usersJson) {
      final user = User.fromJson(jsonDecode(userJson));
      if (user.username.toLowerCase() == username.toLowerCase()) {
        return false; // Пользователь уже существует
      }
    }

    // Создаем нового пользователя
    final userId = _uuid.v4();
    final newUser = User(
      id: userId,
      username: username,
      password: password,
    );
    final newUserModel = UserModel(
      id: userId,
      username: username,
      password: password,
      balance: 3000,
      purchasedStyles: [],
      totalWinnings: 0,
      spinsCount: 0,
      maxWin: 0,
    );

    // Сохраняем в локальное хранилище
    usersJson.add(jsonEncode(newUser.toJson()));
    await prefs.setStringList(_usersKey, usersJson);
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
    
    // Синхронизируем с Firebase
    await _syncService.syncUserData(newUserModel);
    
    _currentUser = newUser;
    notifyListeners();
    return true;
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];

    for (var userJson in usersJson) {
      final user = User.fromJson(jsonDecode(userJson));
      if (user.username.toLowerCase() == username.toLowerCase() && 
          user.password == password) {
        await prefs.setString(_currentUserKey, userJson);
        _currentUser = user;
        
        // Загружаем данные пользователя из Firebase по id
        final userModel = await _syncService.getUserData(user.id);
        if (userModel != null) {
          // Обновляем локальные данные
          await _syncService.syncUserData(userModel);
        }
        
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
      return _currentUser;
    }
    return null;
  }

  Future<void> updateUserData() async {
    if (_currentUser != null) {
      final userModel = await _syncService.getUserData(_currentUser!.id);
      if (userModel != null) {
        await _syncService.syncUserData(userModel);
      }
    }
    await _loadCurrentUser();
    notifyListeners();
  }
} 