// ВНИМАНИЕ: Баланс пользователя НЕЛЬЗЯ хранить или читать через SharedPreferences!
// Используйте только BalanceProvider (Hive) для работы с балансом.
// Этот сервис предназначен только для purchasedStyles, selectedStyle, avatar и lastSync.
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';

class CacheService {
  // static const String _balanceKey = 'user_balance'; // БАЛАНС НЕ ХРАНИТЬ ЗДЕСЬ!
  static const String _purchasedStylesKey = 'purchased_styles';
  static const String _selectedStyleKey = 'selected_style';
  static const String _avatarKey = 'avatar';
  static const String _avatarLocalPathKey = 'avatar_local_path';
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  
  // ---
  // ВНИМАНИЕ: Методы для работы с балансом УДАЛЕНЫ! Используйте только BalanceProvider/Hive.
  // ---
  // static Future<void> saveBalance(int balance) async {
  //   throw Exception('НЕЛЬЗЯ использовать SharedPreferences для баланса! Используйте BalanceProvider/Hive.');
  // }

  // static Future<int?> getBalance() async {
  //   throw Exception('НЕЛЬЗЯ использовать SharedPreferences для баланса! Используйте BalanceProvider/Hive.');
  // }

  static Future<void> savePurchasedStyles(List<String> styles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_purchasedStylesKey, styles);
  }

  static Future<List<String>> getPurchasedStyles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_purchasedStylesKey) ?? ['classic'];
  }

  static Future<void> saveSelectedStyle(String styleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedStyleKey, styleId);
  }

  static Future<String> getSelectedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedStyleKey) ?? 'classic';
  }

  static Future<void> saveAvatar(String avatarUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, avatarUrl);
  }

  static Future<String?> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey);
  }

  static Future<void> saveLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncTimestampKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<bool> needsSync() async {
    final lastSync = await getLastSyncTimestamp();
    if (lastSync == null) return true;
    
    // Синхронизируем если прошло больше 5 минут
    return DateTime.now().difference(lastSync).inMinutes > 5;
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // prefs.remove(_balanceKey); // Баланс не трогать!
    await prefs.remove(_purchasedStylesKey);
    await prefs.remove(_selectedStyleKey);
    await prefs.remove(_avatarKey);
    await prefs.remove(_lastSyncTimestampKey);
  }

  static Future<void> saveAvatarLocalPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarLocalPathKey, path);
  }

  static Future<String?> getAvatarLocalPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarLocalPathKey);
  }

  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_purchasedStylesKey);
      await prefs.remove(_selectedStyleKey);
      await prefs.remove(_avatarKey);
      await prefs.remove(_avatarLocalPathKey);
      await prefs.remove(_lastSyncTimestampKey);
      
      // Очищаем локальный файл аватара, если он существует
      try {
        final localPath = await getAvatarLocalPath();
        if (localPath != null) {
          final file = File(localPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (e) {
        debugPrint('Ошибка при удалении локального файла аватара: $e');
      }
      
      debugPrint('Весь кэш успешно очищен');
    } catch (e) {
      debugPrint('Ошибка при очистке кэша: $e');
    }
  }
} 