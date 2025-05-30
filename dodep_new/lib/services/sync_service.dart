import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class SyncService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService();
  static const String _lastSyncKey = 'last_sync_timestamp';

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncUserData(UserModel user) async {
    // Сохраняем данные локально
    await _databaseService.insertUser(user);

    // Если есть подключение к интернету, синхронизируем с Firebase
    if (await isOnline()) {
      try {
        await _firebaseService.syncUserData(user);
        await _updateLastSyncTime();
      } catch (e) {
        print('Ошибка синхронизации с Firebase: $e');
      }
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    // Сначала пытаемся получить данные из локальной базы
    UserModel? user = await _databaseService.getUser(userId);

    // Если есть подключение к интернету, проверяем обновления в Firebase
    if (await isOnline()) {
      try {
        final firebaseUser = await _firebaseService.getUserData(userId);
        if (firebaseUser != null) {
          // Обновляем локальные данные
          await _databaseService.updateUser(firebaseUser);
          user = firebaseUser;
          await _updateLastSyncTime();
        }
      } catch (e) {
        print('Ошибка получения данных из Firebase: $e');
      }
    }

    return user;
  }

  Future<void> updateUserData(UserModel user) async {
    // Обновляем локальные данные
    await _databaseService.updateUser(user);

    // Если есть подключение к интернету, обновляем в Firebase
    if (await isOnline()) {
      try {
        await _firebaseService.updateUserData(user);
        await _updateLastSyncTime();
      } catch (e) {
        print('Ошибка обновления данных в Firebase: $e');
      }
    }
  }

  Future<void> deleteUserData(String userId) async {
    // Удаляем локальные данные
    await _databaseService.deleteUser(userId);

    // Если есть подключение к интернету, удаляем из Firebase
    if (await isOnline()) {
      try {
        await _firebaseService.deleteUserData(userId);
        await _updateLastSyncTime();
      } catch (e) {
        print('Ошибка удаления данных из Firebase: $e');
      }
    }
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
} 