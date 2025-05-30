import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class AuthService extends ChangeNotifier {
  static const String _currentUserKey = 'currentUser';
  static const String _avatarKeyPrefix = 'avatar_';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  AppUser? _currentUser;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Добавляем константы для Cloudinary
  static const String _cloudName = 'dc4fdzw9j';
  static const String _apiKey = '557119381283486';
  static const String _apiSecret = 'E2W5VrdHy0hzl05RsUAnEpxU_qY';
  static const String _uploadPreset = 'doDEP_avatars';
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    'image',
    cache: false,
  );

  AuthService() {
    // Убираем автоматическую инициализацию из конструктора
  }

  Future<void> initAuthState() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    try {
      debugPrint('Начало инициализации AuthService');
      
      // Проверяем текущее состояние Firebase Auth
      final currentUser = _auth.currentUser;
      debugPrint('Текущий пользователь Firebase Auth: ${currentUser?.uid ?? 'null'}');
      
      if (currentUser != null) {
        debugPrint('Найден текущий пользователь в Firebase Auth: ${currentUser.uid}');
        try {
          // Загружаем данные пользователя из Realtime Database
          final userSnapshot = await _database
              .child('users/${currentUser.uid}')
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Превышено время ожидания при загрузке данных пользователя');
                },
              );

          if (userSnapshot.exists) {
            debugPrint('Данные пользователя найдены в базе');
            final userData = userSnapshot.value as Map<dynamic, dynamic>;
            debugPrint('Данные пользователя: $userData');
            
            _currentUser = AppUser(
              username: userData['username'] as String,
              uid: currentUser.uid,
              balance: userData['balance'] as int? ?? 0,
              purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
              spinsCount: userData['spinsCount'] as int? ?? 0,
              maxWin: userData['maxWin'] as int? ?? 0,
              avatarPath: userData['avatarPath'] as String?,
            );
            
            debugPrint('Создан объект пользователя:');
            debugPrint('Username: ${_currentUser!.username}');
            debugPrint('Balance: ${_currentUser!.balance}');
            debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
            
            await _saveUserDataLocally();
            notifyListeners();
            debugPrint('Данные пользователя успешно загружены и сохранены');
          } else {
            debugPrint('Данные пользователя не найдены в базе');
            // Пытаемся восстановить из локального хранилища
            await _restoreUserStateFromLocal();
          }
        } catch (e) {
          debugPrint('Ошибка при загрузке данных пользователя: $e');
          // Пытаемся восстановить из локального хранилища
          await _restoreUserStateFromLocal();
        }
      } else {
        debugPrint('Текущий пользователь не найден в Firebase Auth');
        // Пытаемся восстановить из локального хранилища
        await _restoreUserStateFromLocal();
      }

      // Настраиваем слушатель изменений состояния аутентификации
      _auth.authStateChanges().listen((firebase_auth.User? user) async {
        debugPrint('Изменение состояния аутентификации: ${user?.uid ?? 'null'}');
        if (user != null) {
          try {
            debugPrint('Загрузка данных для пользователя: ${user.uid}');
            final userSnapshot = await _database
                .child('users/${user.uid}')
                .get()
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Превышено время ожидания при загрузке данных пользователя');
                  },
                );

            if (userSnapshot.exists) {
              debugPrint('Данные пользователя найдены в базе');
              final userData = userSnapshot.value as Map<dynamic, dynamic>;
              debugPrint('Данные пользователя: $userData');
              
              _currentUser = AppUser(
                username: userData['username'] as String,
                uid: user.uid,
                balance: userData['balance'] as int? ?? 0,
                purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
                spinsCount: userData['spinsCount'] as int? ?? 0,
                maxWin: userData['maxWin'] as int? ?? 0,
                avatarPath: userData['avatarPath'] as String?,
              );
              
              debugPrint('Создан объект пользователя:');
              debugPrint('Username: ${_currentUser!.username}');
              debugPrint('Balance: ${_currentUser!.balance}');
              debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
              
              await _saveUserDataLocally();
              notifyListeners();
              debugPrint('Данные пользователя успешно обновлены');
            } else {
              debugPrint('Данные пользователя не найдены в базе');
              await _clearLocalUserData();
              _currentUser = null;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Ошибка при обработке изменения состояния: $e');
            await _clearLocalUserData();
            _currentUser = null;
            notifyListeners();
          }
        } else {
          debugPrint('Пользователь вышел из системы');
          _currentUser = null;
          await _clearLocalUserData();
          notifyListeners();
        }
      });
      
      _isInitialized = true;
      debugPrint('AuthService успешно инициализирован');
    } catch (e) {
      debugPrint('Ошибка при инициализации AuthService: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _restoreUserStateFromLocal() async {
    try {
      debugPrint('Попытка восстановления состояния из локального хранилища');
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson != null) {
        debugPrint('Найдены локальные данные пользователя');
        final userData = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(userData);
        debugPrint('Восстановлено состояние пользователя:');
        debugPrint('Username: ${_currentUser!.username}');
        debugPrint('Balance: ${_currentUser!.balance}');
        debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
        notifyListeners();
      } else {
        debugPrint('Локальные данные пользователя не найдены');
      }
    } catch (e) {
      debugPrint('Ошибка при восстановлении состояния из локального хранилища: $e');
    }
  }

  Future<void> _saveUserDataLocally() async {
    if (_currentUser != null) {
      try {
        debugPrint('Сохранение данных пользователя локально');
        final prefs = await SharedPreferences.getInstance();
        
        // Проверяем, что пользователь все еще авторизован
        final currentAuthUser = _auth.currentUser;
        if (currentAuthUser?.uid != _currentUser!.uid) {
          debugPrint('Ошибка: пользователь не авторизован при сохранении данных');
          return;
        }
        
        // Сохраняем данные пользователя
        final userJson = json.encode(_currentUser!.toJson());
        await prefs.setString(_currentUserKey, userJson);
        
        // Сохраняем токен аутентификации
        final token = await currentAuthUser!.getIdToken();
        if (token != null) {
          await prefs.setString('auth_token', token);
        }
        
        debugPrint('Данные пользователя сохранены локально:');
        debugPrint('Username: ${_currentUser!.username}');
        debugPrint('Balance: ${_currentUser!.balance}');
        debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
      } catch (e) {
        debugPrint('Ошибка при сохранении данных пользователя локально: $e');
      }
    }
  }

  Future<void> _clearLocalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Удаляем все данные пользователя
      await prefs.remove(_currentUserKey);
      await prefs.remove(_currentAvatarKey);
      await prefs.remove('auth_token');
      debugPrint('Локальные данные пользователя очищены');
    } catch (e) {
      debugPrint('Ошибка при очистке локальных данных: $e');
    }
  }

  String get _currentAvatarKey {
    final currentUser = getCurrentUserSync();
    return '${_avatarKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  Future<String?> getCurrentUserAvatar() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Получаем путь к аватару из Firebase
        final snapshot = await _database
            .child('users/${user.uid}/avatarPath')
            .get();

        if (snapshot.exists) {
          final avatarPath = snapshot.value as String?;
          debugPrint('Получен путь к аватару из Firebase: $avatarPath');
          return avatarPath;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка при получении аватара: $e');
      return null;
    }
  }

  Future<void> setCurrentUserAvatar(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Файл изображения не найден: $imagePath');
      }

      debugPrint('Начало процесса обновления аватара');
      
      // Проверяем размер файла
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('Размер файла превышает 5MB');
      }

      // Загружаем новый аватар
      final downloadUrl = await uploadAvatar(file);
      if (downloadUrl == null) {
        throw Exception('Не удалось загрузить аватар');
      }

      debugPrint('Аватар успешно обновлен: $downloadUrl');
    } catch (e) {
      debugPrint('Ошибка при обновлении аватара: $e');
      rethrow;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      debugPrint('Начало процесса регистрации для пользователя: $username');
      
      if (username.isEmpty || password.isEmpty) {
        debugPrint('Имя пользователя или пароль пустые');
        return false;
      }

      if (password.length < 6) {
        debugPrint('Пароль слишком короткий');
        return false;
      }

      final email = '$username@dodepmail.com';
      debugPrint('Используемый email для регистрации: $email');

      // Проверяем существование пользователя в таблице usernames
      final usernameSnapshot = await _database
          .child('usernames')
          .child(username.toLowerCase())
          .get();

      if (usernameSnapshot.exists) {
        debugPrint('Пользователь с таким именем уже существует');
        return false;
      }

      // Проверяем, есть ли старые данные в таблице users
      try {
        final oldUserSnapshot = await _database
            .child('users')
            .orderByChild('username')
            .equalTo(username)
            .once();

        if (oldUserSnapshot.snapshot.exists) {
          debugPrint('Найдены старые данные пользователя');
          // Удаляем старые данные из таблицы users
          for (var child in oldUserSnapshot.snapshot.children) {
            final oldUid = child.key;
            if (oldUid != null) {
              // Удаляем старые данные пользователя
              await _database.child('users/$oldUid').remove();
              debugPrint('Удалены старые данные пользователя: $oldUid');
            }
          }
        }
      } catch (e) {
        debugPrint('Ошибка при проверке старых данных: $e');
      }

      debugPrint('Попытка создания пользователя в Firebase Auth...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Превышено время ожидания при создании пользователя');
        },
      );

      if (userCredential.user != null) {
        debugPrint('Пользователь успешно создан в Firebase Auth');
        
        try {
          final uid = userCredential.user!.uid;
          // Создаем начальные данные пользователя
          final initialUserData = {
            'username': username,
            'createdAt': ServerValue.timestamp,
            'balance': 3000, // Начальный баланс 3000
            'purchasedStyles': [
              'classic', // Классический стиль
            ],
            'selectedStyle': 'classic', // Добавляем выбранный стиль
            'spinsCount': 0,
            'maxWin': 0,
            'avatarPath': null,
          };

          // Создаем записи в базе данных
          await Future.wait([
            _database.child('users/$uid').set(initialUserData),
            _database.child('usernames/${username.toLowerCase()}').set({
              'uid': uid,
              'createdAt': ServerValue.timestamp,
            }),
          ]);
          
          debugPrint('Данные пользователя сохранены в базе');

          // Создаем новый объект пользователя
          final newUser = AppUser.fromJson({
            ...initialUserData,
            'uid': uid,
          });
          
          // Очищаем старые данные перед обновлением
          await _clearLocalUserData();
          
          // Обновляем состояние
          _currentUser = newUser;
          await _saveUserDataLocally();
          
          // Принудительно обновляем все провайдеры
          notifyListeners();
          
          // Добавляем небольшую задержку для гарантии обновления UI
          await Future.delayed(const Duration(milliseconds: 100));
          
          debugPrint('Данные нового пользователя:');
          debugPrint('Username: ${newUser.username}');
          debugPrint('Balance: ${newUser.balance}');
          debugPrint('PurchasedStyles: ${newUser.purchasedStyles}');
          debugPrint('SpinsCount: ${newUser.spinsCount}');
          debugPrint('MaxWin: ${newUser.maxWin}');
          
          debugPrint('Регистрация успешно завершена');
          return true;
        } catch (e) {
          debugPrint('Ошибка при сохранении данных в базу: $e');
          try {
            await userCredential.user?.delete();
            debugPrint('Пользователь удален из Firebase Auth из-за ошибки сохранения данных');
          } catch (e) {
            debugPrint('Ошибка при удалении пользователя: $e');
          }
          return false;
        }
      }
      
      debugPrint('Ошибка: пользователь не создан в Firebase Auth');
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Ошибка Firebase Auth при регистрации: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          debugPrint('Email уже используется');
          break;
        case 'weak-password':
          debugPrint('Слишком слабый пароль');
          break;
        case 'invalid-email':
          debugPrint('Неверный формат email');
          break;
        case 'operation-not-allowed':
          debugPrint('Операция не разрешена');
          break;
        default:
          debugPrint('Неизвестная ошибка Firebase Auth: ${e.code}');
      }
      return false;
    } on TimeoutException {
      debugPrint('Превышено время ожидания при регистрации');
      return false;
    } catch (e) {
      debugPrint('Неизвестная ошибка при регистрации: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      debugPrint('Начало процесса входа для пользователя: $username');
      
      if (username.isEmpty || password.isEmpty) {
        debugPrint('Имя пользователя или пароль пустые');
        return false;
      }

      final email = '$username@dodepmail.com';
      debugPrint('Используемый email: $email');

      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        try {
          debugPrint('Попытка входа #${attempts + 1}');
          
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания при входе');
            },
          );

          if (userCredential.user != null) {
            debugPrint('Вход выполнен успешно в Firebase Auth');
            final uid = userCredential.user!.uid;
            
            // Очищаем старые данные перед загрузкой новых
            await _clearLocalUserData();
            
            // Ждем немного, чтобы Firebase Auth успел обновить состояние
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Проверяем, что пользователь все еще авторизован
            if (_auth.currentUser?.uid != uid) {
              debugPrint('Ошибка: пользователь не авторизован после входа');
              return false;
            }
            
            // Получаем данные пользователя напрямую по UID
            final userSnapshot = await _database
                .child('users/$uid')
                .get()
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Превышено время ожидания при загрузке данных пользователя');
                  },
                );

            if (userSnapshot.exists) {
              debugPrint('Пользователь найден в базе данных');
              final userData = userSnapshot.value as Map<dynamic, dynamic>;
              debugPrint('Данные пользователя из базы: $userData');
              
              if (userData['username'] != username) {
                debugPrint('Ошибка: имя пользователя не совпадает');
                await _auth.signOut();
                return false;
              }

              // Создаем объект пользователя с полными данными
              _currentUser = AppUser(
                username: userData['username'] as String,
                uid: uid,
                balance: userData['balance'] as int? ?? 0,
                purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
                spinsCount: userData['spinsCount'] as int? ?? 0,
                maxWin: userData['maxWin'] as int? ?? 0,
                avatarPath: userData['avatarPath'] as String?,
              );

              debugPrint('Создан объект пользователя:');
              debugPrint('Username: ${_currentUser!.username}');
              debugPrint('Balance: ${_currentUser!.balance}');
              debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');

              // Обновляем запись в usernames если её нет
              try {
                final usernameSnapshot = await _database
                    .child('usernames')
                    .child(username.toLowerCase())
                    .get();

                if (!usernameSnapshot.exists) {
                  await _database.child('usernames/${username.toLowerCase()}').set({
                    'uid': uid,
                    'createdAt': ServerValue.timestamp,
                  });
                  debugPrint('Создана запись в таблице usernames');
                }
              } catch (e) {
                debugPrint('Ошибка при обновлении таблицы usernames: $e');
              }

              // Сохраняем данные локально и обновляем состояние
              await _saveUserDataLocally();
              
              // Принудительно обновляем все провайдеры
              notifyListeners();
              
              // Добавляем небольшую задержку для гарантии обновления UI
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Проверяем финальное состояние
              if (_auth.currentUser?.uid != uid) {
                debugPrint('Ошибка: пользователь не авторизован после сохранения данных');
                await _auth.signOut();
                return false;
              }
              
              debugPrint('Вход успешно завершен');
              return true;
            } else {
              debugPrint('Пользователь не найден в базе данных');
              await _auth.signOut();
              return false;
            }
          }
          
          debugPrint('Вход не выполнен');
          return false;
        } catch (e) {
          debugPrint('Ошибка при входе: $e');
          attempts++;
          if (attempts < maxAttempts) {
            debugPrint('Повторная попытка входа...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }
      
      debugPrint('Превышено максимальное количество попыток входа');
      return false;
    } catch (e) {
      debugPrint('Критическая ошибка при входе: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      await _clearLocalUserData();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка выхода: $e');
    }
  }

  AppUser? getCurrentUserSync() {
    return _currentUser;
  }

  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  Future<void> updateUserData({
    int? balance,
    List<String>? purchasedStyles,
    int? spinsCount,
    int? maxWin,
    String? avatarPath,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final updates = <String, dynamic>{};
        if (balance != null) updates['balance'] = balance;
        if (purchasedStyles != null) updates['purchasedStyles'] = purchasedStyles;
        if (spinsCount != null) updates['spinsCount'] = spinsCount;
        if (maxWin != null) updates['maxWin'] = maxWin;
        if (avatarPath != null) updates['avatarPath'] = avatarPath;

        if (updates.isNotEmpty) {
          debugPrint('Обновление данных пользователя в Firebase: $updates');
          
          // Обновляем данные в Firebase
          await _database
              .child('users/${user.uid}')
              .update(updates)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Превышено время ожидания при обновлении данных');
                },
              );
          
          debugPrint('Данные успешно обновлены в Firebase');
          
          // После успешного обновления в Firebase обновляем локальные данные
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(
              balance: balance ?? _currentUser!.balance,
              purchasedStyles: purchasedStyles ?? _currentUser!.purchasedStyles,
              spinsCount: spinsCount ?? _currentUser!.spinsCount,
              maxWin: maxWin ?? _currentUser!.maxWin,
              avatarPath: avatarPath ?? _currentUser!.avatarPath,
            );
            await _saveUserDataLocally();
            notifyListeners();
            debugPrint('Локальные данные обновлены');
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении данных пользователя: $e');
      rethrow; // Пробрасываем ошибку дальше для обработки в UI
    }
  }

  Future<void> incrementSpinsCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = _database.child('users/${user.uid}');
        
        // Получаем текущее значение
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          final currentCount = (userData['spinsCount'] as int?) ?? 0;
          final newCount = currentCount + 1;
          
          debugPrint('Увеличиваем счетчик вращений: $currentCount -> $newCount');
          
          // Обновляем в базе данных
          await userRef
              .update({'spinsCount': newCount})
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  throw TimeoutException('Превышено время ожидания при обновлении счетчика');
                },
              );
          
          // Обновляем локальное состояние
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(spinsCount: newCount);
            await _saveUserDataLocally();
            notifyListeners();
            debugPrint('Счетчик вращений обновлен: $newCount');
          }
        } else {
          throw Exception('Данные пользователя не найдены');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении счетчика вращений: $e');
      rethrow;
    }
  }

  Future<void> updateMaxWin(int newWin) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = _database.child('users/${user.uid}');
        
        // Получаем текущее значение
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          final currentMaxWin = (userData['maxWin'] as int?) ?? 0;
          
          debugPrint('Проверка максимального выигрыша: текущий $currentMaxWin, новый $newWin');
          
          // Обновляем только если новое значение больше
          if (newWin > currentMaxWin) {
            await userRef
                .update({'maxWin': newWin})
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Превышено время ожидания при обновлении максимального выигрыша');
                  },
                );
            
            // Обновляем локальное состояние
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(maxWin: newWin);
              await _saveUserDataLocally();
              notifyListeners();
              debugPrint('Максимальный выигрыш обновлен: $newWin');
            }
          } else {
            debugPrint('Новый выигрыш ($newWin) не больше текущего максимума ($currentMaxWin)');
          }
        } else {
          throw Exception('Данные пользователя не найдены');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении максимального выигрыша: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(int newBalance) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = _database.child('users/${user.uid}');
        
        debugPrint('Обновление баланса: $newBalance');
        
        // Обновляем в базе данных
        await userRef
            .update({'balance': newBalance})
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Превышено время ожидания при обновлении баланса');
              },
            );
        
        // Обновляем локальное состояние
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(balance: newBalance);
          await _saveUserDataLocally();
          notifyListeners();
          debugPrint('Баланс обновлен: $newBalance');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении баланса: $e');
      rethrow;
    }
  }

  Future<void> addPurchasedStyle(String styleId) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = _database.child('users/${user.uid}');
        
        debugPrint('Добавление купленного стиля: $styleId');
        
        // Получаем текущие стили
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final userData = snapshot.value as Map<dynamic, dynamic>;
          final currentStyles = (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [];
          
          if (!currentStyles.contains(styleId)) {
            final updatedStyles = [...currentStyles, styleId];
            
            // Обновляем в базе данных
            await userRef
                .update({'purchasedStyles': updatedStyles})
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Превышено время ожидания при добавлении стиля');
                  },
                );
            
            // Обновляем локальное состояние
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(
                purchasedStyles: updatedStyles,
              );
              await _saveUserDataLocally();
              notifyListeners();
              debugPrint('Стиль успешно добавлен: $styleId');
            }
          } else {
            debugPrint('Стиль уже куплен: $styleId');
          }
        } else {
          throw Exception('Данные пользователя не найдены');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении купленного стиля: $e');
      rethrow;
    }
  }

  Future<void> setUserAvatar(String path) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Обновление аватара в Firebase: $path');
        
        // Обновляем путь к аватару в Firebase
        await _database
            .child('users/${user.uid}')
            .update({'avatarPath': path})
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Превышено время ожидания при обновлении аватара');
              },
            );
        
        // Обновляем локальное состояние
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(avatarPath: path);
          await _saveUserDataLocally();
          notifyListeners();
          debugPrint('Аватар успешно обновлен в Firebase и локально');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении аватара: $e');
      rethrow;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Начало процесса удаления аккаунта');
        
        // Получаем данные пользователя для удаления связанных записей
        final userSnapshot = await _database
            .child('users/${user.uid}')
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          final username = userData['username'] as String?;
          
          // Удаляем все данные пользователя
          try {
            // Удаляем запись из таблицы usernames
            if (username != null) {
              await _database
                  .child('usernames/${username.toLowerCase()}')
                  .remove();
              debugPrint('Удалена запись из таблицы usernames');
            }

            // Удаляем данные пользователя
            await _database
                .child('users/${user.uid}')
                .remove();
            debugPrint('Удалены данные пользователя');

            // Удаляем локальные данные
            await _clearLocalUserData();
            
            // Удаляем аккаунт из Firebase Auth
            await user.delete();
            debugPrint('Аккаунт удален из Firebase Auth');

            _currentUser = null;
            notifyListeners();
            debugPrint('Аккаунт успешно удален');
            return true;
          } catch (e) {
            debugPrint('Ошибка при удалении данных пользователя: $e');
            return false;
          }
        } else {
          debugPrint('Данные пользователя не найдены в базе');
          // Если данных нет в базе, просто удаляем аккаунт
          try {
            await user.delete();
            _currentUser = null;
            await _clearLocalUserData();
            notifyListeners();
            debugPrint('Аккаунт удален (данные не найдены)');
            return true;
          } catch (e) {
            debugPrint('Ошибка при удалении аккаунта: $e');
            return false;
          }
        }
      }
      debugPrint('Пользователь не авторизован');
      return false;
    } catch (e) {
      debugPrint('Критическая ошибка при удалении аккаунта: $e');
      return false;
    }
  }

  // Добавляем новый метод для принудительного обновления данных
  Future<void> forceRefreshUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Принудительное обновление данных пользователя');
        
        // Очищаем старые данные
        await _clearLocalUserData();
        
        // Получаем свежие данные из Firebase
        final userSnapshot = await _database
            .child('users/${user.uid}')
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          
          // Создаем новый объект пользователя
          final newUser = AppUser(
            username: userData['username'] as String,
            uid: user.uid,
            balance: userData['balance'] as int? ?? 0,
            purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
            spinsCount: userData['spinsCount'] as int? ?? 0,
            maxWin: userData['maxWin'] as int? ?? 0,
            avatarPath: userData['avatarPath'] as String?,
          );

          // Обновляем состояние
          _currentUser = newUser;
          await _saveUserDataLocally();
          
          // Принудительно обновляем все провайдеры
          notifyListeners();
          
          debugPrint('Данные пользователя успешно обновлены');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при принудительном обновлении данных: $e');
    }
  }

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Пользователь не авторизован при загрузке аватара');
        return null;
      }

      // Проверяем размер файла
      final fileSize = await imageFile.length();
      debugPrint('Размер файла: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('Размер файла превышает 5MB');
      }

      // Удаляем старый аватар, если он существует
      final currentAvatarPath = _currentUser?.avatarPath;
      if (currentAvatarPath != null && currentAvatarPath.isNotEmpty) {
        try {
          // Извлекаем public_id из URL
          final uri = Uri.parse(currentAvatarPath);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            // Получаем public_id из пути, учитывая папку dodep/avatars
            final path = pathSegments.join('/');
            final publicId = 'dodep/avatars/${path.split('/').last.split('.')[0]}';
            
            debugPrint('Удаление старого аватара с public_id: $publicId');
            
            // Формируем подпись для удаления
            final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
            final params = {
              'public_id': publicId,
              'timestamp': timestamp,
            };
            
            // Сортируем параметры для создания подписи
            final sortedParams = params.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            
            // Создаем строку для подписи
            final signString = sortedParams
                .map((e) => '${e.key}=${e.value}')
                .join('&') + _apiSecret;
            
            // Генерируем подпись
            final signature = sha1.convert(utf8.encode(signString)).toString();
            
            // Удаляем файл через API Cloudinary
            final response = await http.delete(
              Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
              body: {
                'public_id': publicId,
                'api_key': _apiKey,
                'timestamp': timestamp,
                'signature': signature,
              },
            );
            
            if (response.statusCode == 200) {
              debugPrint('Старый аватар успешно удален из Cloudinary');
            } else {
              debugPrint('Ошибка при удалении старого аватара: ${response.statusCode}');
              debugPrint('Ответ сервера: ${response.body}');
            }
          }
        } catch (e) {
          debugPrint('Ошибка при удалении старого аватара из Cloudinary: $e');
          // Продолжаем загрузку нового аватара даже если не удалось удалить старый
        }
      }

      debugPrint('Начало загрузки нового аватара в Cloudinary');
      debugPrint('Путь к файлу: ${imageFile.path}');

      try {
        // Создаем уникальное имя файла
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'avatar_${user.uid}_$timestamp';
        
        // Подготавливаем параметры для подписи
        final timestampStr = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
        final params = {
          'timestamp': timestampStr,
          'public_id': fileName,
          'folder': 'dodep/avatars',
          'tags': 'avatar,${user.uid}',
          'transformation': 'w_500,h_500,c_fill,g_face,q_auto,f_auto',
        };

        // Сортируем параметры для создания подписи
        final sortedParams = params.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        
        // Создаем строку для подписи
        final signString = sortedParams
            .map((e) => '${e.key}=${e.value}')
            .join('&') + _apiSecret;
        
        // Генерируем подпись
        final signature = sha1.convert(utf8.encode(signString)).toString();
        
        // Формируем URL для загрузки
        final uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
        
        // Создаем multipart запрос
        final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
          ..fields['api_key'] = _apiKey
          ..fields['signature'] = signature
          ..fields.addAll(params)
          ..files.add(await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ));

        // Отправляем запрос
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final secureUrl = responseData['secure_url'] as String?;
          
          if (secureUrl != null) {
            debugPrint('Аватар успешно загружен в Cloudinary: $secureUrl');

            // Обновляем путь к аватару в базе данных
            await _database
                .child('users/${user.uid}')
                .update({'avatarPath': secureUrl})
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    throw TimeoutException('Превышено время ожидания при обновлении пути к аватару');
                  },
                );

            // Обновляем локальное состояние
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(avatarPath: secureUrl);
              await _saveUserDataLocally();
              notifyListeners();
            }

            return secureUrl;
          } else {
            throw Exception('Ошибка при загрузке изображения: не удалось получить URL');
          }
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error']?['message'] as String?;
          throw Exception('Ошибка при загрузке в Cloudinary: $errorMessage');
        }
      } catch (e) {
        debugPrint('Неожиданная ошибка при загрузке в Cloudinary: $e');
        throw Exception('Ошибка при загрузке аватара: $e');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке аватара: $e');
      rethrow;
    }
  }

  Future<void> deleteAvatar() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final currentAvatarPath = _currentUser?.avatarPath;
      if (currentAvatarPath != null && currentAvatarPath.isNotEmpty) {
        try {
          // Извлекаем public_id из URL
          final uri = Uri.parse(currentAvatarPath);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            // Получаем public_id из пути
            final path = pathSegments.join('/');
            final publicId = path.split('/').last.split('.')[0];
            
            // Формируем подпись для удаления
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final signature = _generateSignature(publicId, timestamp);
            
            // Удаляем файл через API Cloudinary
            final response = await http.delete(
              Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
              body: {
                'public_id': publicId,
                'api_key': _apiKey,
                'timestamp': timestamp.toString(),
                'signature': signature,
              },
            );
            if (response.statusCode == 200) {
              debugPrint('Аватар удален из Cloudinary');
            } else {
              debugPrint('Ошибка при удалении аватара: ${response.statusCode}');
              debugPrint('Ответ сервера: ${response.body}');
            }
          }
        } catch (e) {
          debugPrint('Ошибка при удалении аватара из Cloudinary: $e');
        }
      }

      // Очищаем путь к аватару в базе данных
      await _database
          .child('users/${user.uid}')
          .update({'avatarPath': null})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания при удалении аватара');
            },
          );

      // Обновляем локальное состояние
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(avatarPath: null);
        await _saveUserDataLocally();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при удалении аватара: $e');
      rethrow;
    }
  }

  // Добавляем метод для генерации подписи
  String _generateSignature(String publicId, int timestamp) {
    final params = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytes = utf8.encode(params);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
} 