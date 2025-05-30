import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';
  static const String _avatarKeyPrefix = 'avatar_';
  User? _currentUser;

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
    if (_currentUser == null) {
      _loadCurrentUser();
    }
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
    final newUser = User(username: username, password: password);
    usersJson.add(jsonEncode(newUser.toJson()));
    await prefs.setStringList(_usersKey, usersJson);
    
    // Автоматически входим после регистрации
    await prefs.setString(_currentUserKey, jsonEncode(newUser.toJson()));
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

  // Метод для обновления данных при смене пользователя
  Future<void> updateUserData() async {
    await _loadCurrentUser();
    notifyListeners();
  }
} 