import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'cache_service.dart';
import '../providers/balance_provider.dart';
import 'package:provider/provider.dart';
import '../utils/global_keys.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class AuthService extends ChangeNotifier {
  static const String _currentUserKey = 'currentUser';
  static const String _avatarKeyPrefix = 'avatar_';
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AppUser? _currentUser;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isOnline = true;
  Timer? _syncTimer;
  final _connectivity = Connectivity();
  bool _isUpdating = false;

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
    _initConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _startSyncTimer();
      }
    } catch (e) {
      debugPrint('Ошибка при проверке подключения: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = !results.contains(ConnectivityResult.none);
      if (_isOnline) {
        _startSyncTimer();
        _syncWithFirestore();
      } else {
        _syncTimer?.cancel();
      }
      notifyListeners();
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_isOnline) {
        _syncWithFirestore();
      }
    });
  }

  Future<void> _syncWithFirestore() async {
    if (!_isOnline || _currentUser == null) return;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final localUser = _currentUser!;

        // Синхронизируем только если данные в Firestore новее
        if (userData['lastUpdated'] != null) {
          final serverTimestamp = (userData['lastUpdated'] as Timestamp).toDate();
          final localtimestamp = localUser.lastUpdated ?? DateTime.now().subtract(const Duration(days: 1));

          if (serverTimestamp.isAfter(localtimestamp)) {
            _currentUser = AppUser.fromJson({
              ...userData,
              'uid': _currentUser!.uid,
            });
            await _saveUserDataLocally();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Ошибка при синхронизации с Firestore: $e');
    }
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
          // Загружаем данные пользователя из Firestore
          final userDoc = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            debugPrint('Данные пользователя найдены в Firestore');
            final userData = userDoc.data() as Map<String, dynamic>;
            debugPrint('Данные пользователя: $userData');
            
            _currentUser = AppUser(
              username: userData['username'] as String,
              uid: currentUser.uid,
              balance: userData['balance'] as int? ?? 0,
              purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
              spinsCount: userData['spinsCount'] as int? ?? 0,
              maxWin: userData['maxWin'] as int? ?? 0,
              avatarPath: userData['avatarPath'] as String?,
              lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate(),
            );
            
            // Кэшируем аватар при наличии url
            final avatarUrl = userData['avatarPath'] as String?;
            if (avatarUrl != null && avatarUrl.isNotEmpty) {
              try {
                final response = await http.get(Uri.parse(avatarUrl));
                if (response.statusCode == 200) {
                  final dir = await getApplicationDocumentsDirectory();
                  final localPath = '${dir.path}/profile_avatar.jpg';
                  final localFile = File(localPath);
                  await localFile.writeAsBytes(response.bodyBytes);
                  await CacheService.saveAvatarLocalPath(localPath);
                  debugPrint('initAuthState: аватар кэширован локально: $localPath');
                }
              } catch (e) {
                debugPrint('initAuthState: ошибка при кэшировании аватара: $e');
              }
            }
            
            debugPrint('Создан объект пользователя:');
            debugPrint('Username: ${_currentUser!.username}');
            debugPrint('Balance: ${_currentUser!.balance}');
            debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
            
            await _saveUserDataLocally();
            notifyListeners();
            debugPrint('Данные пользователя успешно загружены и сохранены');
          } else {
            debugPrint('Данные пользователя не найдены в Firestore');
            await _restoreUserStateFromLocal();
          }
        } catch (e) {
          debugPrint('Ошибка при загрузке данных пользователя: $e');
          await _restoreUserStateFromLocal();
        }
      } else {
        debugPrint('Текущий пользователь не найден в Firebase Auth');
        await _restoreUserStateFromLocal();
      }

      // Настраиваем слушатель изменений состояния аутентификации
      _auth.authStateChanges().listen((firebase_auth.User? user) async {
        debugPrint('Изменение состояния аутентификации: ${user?.uid ?? 'null'}');
        if (user != null) {
          try {
            debugPrint('Загрузка данных для пользователя: ${user.uid}');
            final userDoc = await _firestore
                .collection('users')
                .doc(user.uid)
                .get();

            if (userDoc.exists) {
              debugPrint('Данные пользователя найдены в Firestore');
              final userData = userDoc.data() as Map<String, dynamic>;
              debugPrint('Данные пользователя: $userData');
              try {
                final context = navigatorKey.currentContext;
                final balanceProvider = context != null ? Provider.of<BalanceProvider>(context, listen: false) : null;
                if (balanceProvider != null && balanceProvider.justSynced) {
                  debugPrint('[AuthService] authStateChanges: justSynced=true, не обновляем баланс из Firestore, оставляем локальный');
                  _currentUser = _currentUser?.copyWith(
                    purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? _currentUser!.purchasedStyles,
                    selectedStyle: userData['selectedStyle'] as String? ?? _currentUser!.selectedStyle,
                    spinsCount: userData['spinsCount'] as int? ?? _currentUser!.spinsCount,
                    maxWin: userData['maxWin'] as int? ?? _currentUser!.maxWin,
                    avatarPath: userData['avatarPath'] as String? ?? _currentUser!.avatarPath,
                    lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate() ?? _currentUser!.lastUpdated,
                  );
                } else {
                  _currentUser = AppUser(
                    username: userData['username'] as String,
                    uid: user.uid,
                    balance: userData['balance'] as int? ?? 0,
                    purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
                    selectedStyle: userData['selectedStyle'] as String? ?? 'classic',
                    spinsCount: userData['spinsCount'] as int? ?? 0,
                    maxWin: userData['maxWin'] as int? ?? 0,
                    avatarPath: userData['avatarPath'] as String?,
                    lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate(),
                  );
                }
              } catch (e) {
                _currentUser = AppUser(
                  username: userData['username'] as String,
                  uid: user.uid,
                  balance: userData['balance'] as int? ?? 0,
                  purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
                  selectedStyle: userData['selectedStyle'] as String? ?? 'classic',
                  spinsCount: userData['spinsCount'] as int? ?? 0,
                  maxWin: userData['maxWin'] as int? ?? 0,
                  avatarPath: userData['avatarPath'] as String?,
                  lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate(),
                );
              }
              await _saveUserDataLocally();
              notifyListeners();
              debugPrint('Данные пользователя успешно обновлены');
            } else {
              debugPrint('Данные пользователя не найдены в Firestore');
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

  Future<void> saveUserDataToFirestore() async {
    if (!_isOnline || _currentUser == null) return;

    try {
      // Получаем актуальный баланс из Hive (или через BalanceProvider)
      int actualBalance = _currentUser!.balance;
      try {
        final box = Hive.box<int>('balances');
        final hiveKey = 'balance_${_currentUser!.username}';
        if (box.containsKey(hiveKey)) {
          actualBalance = box.get(hiveKey) ?? actualBalance;
        }
      } catch (e) {
        debugPrint('Не удалось получить баланс из Hive для sync: $e');
      }
      _currentUser = _currentUser!.copyWith(balance: actualBalance);
      await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            ..._currentUser!.toJson(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      debugPrint('Данные пользователя сохранены в Firestore');
    } catch (e) {
      debugPrint('Ошибка при сохранении данных в Firestore: $e');
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

  /// Возвращает локальный путь к аватару, если есть, иначе url из Firestore
  Future<String?> getCurrentUserAvatarOfflineFirst() async {
    try {
      final localPath = await CacheService.getAvatarLocalPath();
      if (localPath != null && await File(localPath).exists()) {
        debugPrint('Аватар найден локально: $localPath');
        return localPath;
      }
      // Если нет локального файла — пробуем url из Firestore
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          final userData = snapshot.data() as Map<String, dynamic>;
          final avatarPath = userData['avatarPath'] as String?;
          debugPrint('Получен путь к аватару из Firestore: $avatarPath');
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
      // Обновляем путь к аватару в Firestore
      await setUserAvatar(downloadUrl);

      // Сразу копируем локальный файл в кэш (profile_avatar.jpg)
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/profile_avatar.jpg';
        await file.copy(localPath);
        await CacheService.saveAvatarLocalPath(localPath);
        debugPrint('Локальный аватар обновлён сразу после смены: $localPath');
      } catch (e) {
        debugPrint('Ошибка при локальном обновлении аватара: $e');
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
      final usernameSnapshot = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (usernameSnapshot.exists) {
        debugPrint('Пользователь с таким именем уже существует');
        return false;
      }

      debugPrint('Попытка создания пользователя в Firebase Auth...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        debugPrint('Пользователь успешно создан в Firebase Auth');
        
        try {
          final uid = userCredential.user!.uid;
          // Создаем начальные данные пользователя
          final initialUserData = {
            'username': username,
            'createdAt': FieldValue.serverTimestamp(),
            'balance': 3000, // Начальный баланс 3000
            'purchasedStyles': ['classic'], // Классический стиль
            'selectedStyle': 'classic', // Добавляем выбранный стиль
            'spinsCount': 0,
            'maxWin': 0,
            'avatarPath': null,
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          // Создаем записи в базе данных
          await Future.wait([
            _firestore.collection('users').doc(uid).set(initialUserData),
            _firestore.collection('usernames').doc(username.toLowerCase()).set({
              'uid': uid,
              'createdAt': FieldValue.serverTimestamp(),
            }),
          ]);
          
          debugPrint('Данные пользователя сохранены в базе');

          // Создаем новый объект пользователя
          _currentUser = AppUser(
            username: username,
            uid: uid,
            balance: 3000,
            purchasedStyles: ['classic'],
            selectedStyle: 'classic',
            spinsCount: 0,
            maxWin: 0,
            avatarPath: null,
            lastUpdated: DateTime.now(),
          );
          
          // Сохраняем в кэш
          // await CacheService.saveBalance(3000); // БАЛАНС НЕ ХРАНИТЬ В SharedPreferences! Используйте только BalanceProvider/Hive.
          await CacheService.savePurchasedStyles(['classic']);
          await CacheService.saveSelectedStyle('classic');
          await CacheService.saveLastSyncTimestamp();
          
          // Принудительно обновляем все провайдеры
          notifyListeners();
          
          debugPrint('Данные нового пользователя:');
          debugPrint('Username: ${_currentUser!.username}');
          debugPrint('Balance: ${_currentUser!.balance}');
          debugPrint('PurchasedStyles: ${_currentUser!.purchasedStyles}');
          debugPrint('SpinsCount: ${_currentUser!.spinsCount}');
          debugPrint('MaxWin: ${_currentUser!.maxWin}');
          
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

      // Сначала проверяем существование пользователя в Firestore
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(username.toLowerCase())
          .get();

      if (!usernameDoc.exists) {
        debugPrint('Пользователь не найден в базе данных');
        return false;
      }

      // Пытаемся войти
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            debugPrint('Вход выполнен успешно в Firebase Auth');
            final uid = userCredential.user!.uid;
            
        // Получаем данные пользователя
            final userDoc = await _firestore
                .collection('users')
                .doc(uid)
                .get();

            if (userDoc.exists) {
          debugPrint('Данные пользователя найдены в Firestore');
              final userData = userDoc.data() as Map<String, dynamic>;
          
              _currentUser = AppUser(
                username: userData['username'] as String,
                uid: uid,
                balance: userData['balance'] as int? ?? 0,
                purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
            selectedStyle: userData['selectedStyle'] as String? ?? 'classic',
                spinsCount: userData['spinsCount'] as int? ?? 0,
                maxWin: userData['maxWin'] as int? ?? 0,
                avatarPath: userData['avatarPath'] as String?,
                lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate(),
              );

          // Кэшируем аватар при наличии url
          final avatarUrl = userData['avatarPath'] as String?;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(avatarUrl));
              if (response.statusCode == 200) {
                final dir = await getApplicationDocumentsDirectory();
                final localPath = '${dir.path}/profile_avatar.jpg';
                final localFile = File(localPath);
                await localFile.writeAsBytes(response.bodyBytes);
                await CacheService.saveAvatarLocalPath(localPath);
                debugPrint('login: аватар кэширован локально: $localPath');
              }
            } catch (e) {
              debugPrint('login: ошибка при кэшировании аватара: $e');
            }
          }

          // Сохраняем в кэш
          // await CacheService.saveBalance(_currentUser!.balance); // БАЛАНС НЕ ХРАНИТЬ В SharedPreferences! Используйте только BalanceProvider/Hive.
          await CacheService.savePurchasedStyles(_currentUser!.purchasedStyles);
          await CacheService.saveSelectedStyle(_currentUser!.selectedStyle);
          if (_currentUser!.avatarPath != null) {
            await CacheService.saveAvatar(_currentUser!.avatarPath!);
          }
          await CacheService.saveLastSyncTimestamp();
              
              notifyListeners();
              debugPrint('Вход успешно завершен');
              return true;
            } else {
          debugPrint('Данные пользователя не найдены в Firestore');
              await _auth.signOut();
              return false;
            }
          }
          
          debugPrint('Вход не выполнен');
          return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Ошибка Firebase Auth при входе: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Неизвестная ошибка при входе: $e');
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

  Future<void> updateUserData() async {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      final context = navigatorKey.currentContext;
      final balanceProvider = context != null ? Provider.of<BalanceProvider>(context, listen: false) : null;
      if (balanceProvider != null && balanceProvider.isSyncingBalance) {
        debugPrint('[AuthService] updateUserData: идёт sync баланса, пропускаем загрузку из Firestore');
        _isUpdating = false;
        return;
      }
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('updateUserData: пользователь не авторизован, пропуск');
        _isUpdating = false;
        return;
      }
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        _currentUser = null;
        await _clearLocalUserData();
        notifyListeners();
        return;
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      try {
        if (balanceProvider != null && balanceProvider.justSynced) {
          debugPrint('[AuthService] updateUserData: justSynced=true, не обновляем баланс из Firestore, оставляем локальный');
          _currentUser = _currentUser?.copyWith(
            purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? _currentUser!.purchasedStyles,
            selectedStyle: userData['selectedStyle'] as String? ?? _currentUser!.selectedStyle,
            spinsCount: userData['spinsCount'] as int? ?? _currentUser!.spinsCount,
            maxWin: userData['maxWin'] as int? ?? _currentUser!.maxWin,
            avatarPath: userData['avatarPath'] as String? ?? _currentUser!.avatarPath,
            lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate() ?? _currentUser!.lastUpdated,
          );
        } else {
          _currentUser = AppUser.fromJson(userData);
        }
      } catch (e) {
        _currentUser = AppUser.fromJson(userData);
      }
      await _saveUserDataLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при обновлении данных пользователя: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> updateBalance(int newBalance) async {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('updateBalance: пользователь не авторизован, пропуск');
        _isUpdating = false;
        return;
      }
      await _firestore.collection('users').doc(user.uid).set({
        'balance': newBalance,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(balance: newBalance, lastUpdated: DateTime.now());
        await _saveUserDataLocally();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении баланса: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> incrementSpinsCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentCount = (userData['spinsCount'] as int?) ?? 0;
          final newCount = currentCount + 1;
          
          debugPrint('Увеличиваем счетчик вращений: $currentCount -> $newCount');
          
          // Обновляем в базе данных
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'spinsCount': newCount});
          
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
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentMaxWin = (userData['maxWin'] as int?) ?? 0;
          
          debugPrint('Проверка максимального выигрыша: текущий $currentMaxWin, новый $newWin');
          
          // Обновляем только если новое значение больше
          if (newWin > currentMaxWin) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'maxWin': newWin});
            
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

  Future<void> addPurchasedStyle(String styleId) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

          final userData = userDoc.data() as Map<String, dynamic>;
      List<String> purchasedStyles = List<String>.from(userData['purchasedStyles'] ?? []);
      
      if (!purchasedStyles.contains(styleId)) {
        purchasedStyles.add(styleId);
        await _firestore.collection('users').doc(user.uid).set({
          'purchasedStyles': purchasedStyles,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

          if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(purchasedStyles: purchasedStyles);
            await _saveUserDataLocally();
            notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении купленного стиля: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> setSelectedStyle(String styleId) async {
    if (_isUpdating) return;
    _isUpdating = true;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'selectedStyle': styleId,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

            if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(selectedStyle: styleId);
              await _saveUserDataLocally();
              notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при установке выбранного стиля: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> setUserAvatar(String path) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Обновление аватара в Firestore: $path');
        
        // Обновляем путь к аватару в Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'avatarPath': path});
        
        // Обновляем локальное состояние
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(avatarPath: path);
          await _saveUserDataLocally();
          notifyListeners();
          debugPrint('Аватар успешно обновлен в Firestore и локально');
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
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final username = userData['username'] as String?;
          
          // Удаляем все данные пользователя
          try {
            // Удаляем запись из таблицы usernames
            if (username != null) {
              await _firestore
                  .collection('usernames')
                  .doc(username.toLowerCase())
                  .delete();
              debugPrint('Удалена запись из таблицы usernames');
            }

            // Удаляем данные пользователя
            await _firestore
                .collection('users')
                .doc(user.uid)
                .delete();
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
      final context = navigatorKey.currentContext;
      final balanceProvider = context != null ? Provider.of<BalanceProvider>(context, listen: false) : null;
      if (balanceProvider != null && balanceProvider.isSyncingBalance) {
        debugPrint('[AuthService] forceRefreshUserData: идёт sync баланса, пропускаем загрузку из Firestore');
        return;
      }
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Принудительное обновление данных пользователя');
        
        // Очищаем старые данные
        await _clearLocalUserData();
        
        // Получаем свежие данные из Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          // Создаем новый объект пользователя
          final newUser = AppUser(
            username: userData['username'] as String,
            uid: user.uid,
            balance: userData['balance'] as int? ?? 0,
            purchasedStyles: (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [],
            spinsCount: userData['spinsCount'] as int? ?? 0,
            maxWin: userData['maxWin'] as int? ?? 0,
            avatarPath: userData['avatarPath'] as String?,
            lastUpdated: (userData['lastUpdated'] as Timestamp?)?.toDate(),
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
            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'avatarPath': secureUrl});

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
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'avatarPath': null});

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

  // Публичный метод для обновления баланса локального пользователя (только локально, без Firestore)
  void setCurrentUserBalance(int balance) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(balance: balance, lastUpdated: DateTime.now());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
} 