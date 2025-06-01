import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'dart:async'; // Добавляем импорт для TimeoutException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../models/app_user.dart';
import 'theme_provider.dart';
import '../utils/global_keys.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/cache_service.dart';

class SlotStyle {
  final String id;
  final String name;
  final String imageAsset;
  final int? price;

  const SlotStyle({
    required this.id,
    required this.name,
    required this.imageAsset,
    this.price,
  });
}

class StyleProvider extends ChangeNotifier {
  static const String _boughtStylesKeyPrefix = 'bought_slot_styles_';
  static const String _selectedStyleKeyPrefix = 'selected_style_';
  
  // Список всех доступных стилей слотов
  final List<SlotStyle> _allSlotStyles = const [
    SlotStyle(id: 'classic', name: 'Классика', imageAsset: 'assets/images/logo.png'), // Классический стиль
    SlotStyle(id: 'fantasy_gacha', name: 'Фэнтези-гача', imageAsset: 'assets/images/fantasystyle.png', price: 3000),
    SlotStyle(id: 'dresnya', name: 'Дресня', imageAsset: 'assets/images/dresnyastyle.png', price: 1000),
    SlotStyle(id: 'tokyopuk', name: 'Токийский пук', imageAsset: 'assets/images/tokyopukstyle.png', price: 4500),
    SlotStyle(id: 'lego', name: 'Лего', imageAsset: 'assets/images/legostyle.png', price: 6000),
    SlotStyle(id: 'minecraft', name: 'Майнкрафт', imageAsset: 'assets/images/minecraftstyle.png', price: 3800),
    SlotStyle(id: 'doka3', name: 'Дока 3', imageAsset: 'assets/images/doka3style.png', price: 7000),
    SlotStyle(id: 'yamete', name: 'Ямете кудасай', imageAsset: 'assets/images/japanstyle.png', price: 2500),
  ];

  List<String> _boughtStyleIds = ['classic']; // Список ID купленных стилей, по умолчанию есть 'classic'
  String _selectedStyleId = 'classic'; // ID текущего выбранного стиля
  SharedPreferences? _prefs;
  late AuthService _authService;
  bool _isInitialized = false;
  bool _isLoading = false;

  StyleProvider() {
    // Инициализация будет происходить через ChangeNotifierProxyProvider
  }

  void updateAuthService(AuthService authService) {
    if (!_isInitialized) {
      _authService = authService;
      _initializeStyles();
    }
  }

  // Геттеры
  List<SlotStyle> get allSlotStyles => _allSlotStyles;
  List<String> get boughtStyleIds => _boughtStyleIds;
  String get selectedStyleId => _selectedStyleId;

  String get _currentBoughtStylesKey {
    final currentUser = _authService.getCurrentUserSync();
    return '${_boughtStylesKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  String get _currentSelectedStyleKey {
    final currentUser = _authService.getCurrentUserSync();
    return '${_selectedStyleKeyPrefix}${currentUser?.username ?? 'guest'}';
  }

  Future<void> initialize() async {
    if (!_isInitialized && !_isLoading) {
      await _initializeStyles();
    }
  }

  Future<void> _initializeStyles() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      _prefs = await SharedPreferences.getInstance();
      final currentUser = _authService.getCurrentUserSync();

      if (currentUser != null) {
        // Загружаем из кэша
        _boughtStyleIds = await CacheService.getPurchasedStyles();
        _selectedStyleId = await CacheService.getSelectedStyle();

        // Проверяем подключение к интернету
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          // Если есть интернет, обновляем из Firestore
          await _updateFromFirebase(currentUser);
        }
      } else {
        _loadFromLocalStorage();
      }
    } catch (e) {
      debugPrint('Ошибка при инициализации стилей: $e');
      _loadFromLocalStorage();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _updateFromFirebase(AppUser currentUser) async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Обновляем купленные стили
        final purchasedStyles = (userData['purchasedStyles'] as List<dynamic>?)?.cast<String>() ?? [];
        if (!listEquals(purchasedStyles, _boughtStyleIds)) {
          _boughtStyleIds = purchasedStyles;
          if (!_boughtStyleIds.contains('classic')) {
            _boughtStyleIds.add('classic');
            await _authService.addPurchasedStyle('classic');
          }
          // Сохраняем в кэш
          await CacheService.savePurchasedStyles(_boughtStyleIds);
          notifyListeners();
        }

        // Обновляем выбранный стиль
        final selectedStyle = userData['selectedStyle'] as String?;
        if (selectedStyle != null && _boughtStyleIds.contains(selectedStyle) && selectedStyle != _selectedStyleId) {
          _selectedStyleId = selectedStyle;
          // Сохраняем в кэш
          await CacheService.saveSelectedStyle(_selectedStyleId);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении стилей из Firestore: $e');
    } finally {
      _isLoading = false;
    }
  }

  void _loadFromLocalStorage() {
    final savedStyles = _prefs!.getStringList(_currentBoughtStylesKey);
    if (savedStyles != null) {
      _boughtStyleIds = savedStyles;
    } else {
      _boughtStyleIds = ['classic'];
    }
    
    final savedSelectedStyle = _prefs!.getString(_currentSelectedStyleKey);
    if (savedSelectedStyle != null && _boughtStyleIds.contains(savedSelectedStyle)) {
      _selectedStyleId = savedSelectedStyle;
    } else {
      _selectedStyleId = 'classic';
    }
    
    debugPrint('Загружены стили из локального хранилища: $_boughtStyleIds');
    debugPrint('Выбранный стиль: $_selectedStyleId');
  }

  // Покупка стиля
  Future<bool> buyStyle(SlotStyle style) async {
    try {
      if (_boughtStyleIds.contains(style.id)) {
        debugPrint('Стиль \x1b[36m${style.id}\x1b[0m уже куплен');
        return false;
      }
      if (style.price == null) {
        debugPrint('Стиль \x1b[36m${style.id}\x1b[0m не имеет цены');
        return false;
      }
      final currentUser = _authService.getCurrentUserSync();
      if (currentUser == null) {
        debugPrint('Пользователь не авторизован');
        return false;
      }
      // --- Всегда обновляем локально ---
      final updatedStyles = List<String>.from(_boughtStyleIds)..add(style.id);
      await CacheService.savePurchasedStyles(updatedStyles);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_currentBoughtStylesKey, updatedStyles);
      _boughtStyleIds = updatedStyles;
      notifyListeners();

      // --- Возвращаем успех сразу после локального обновления ---
      // А sync с сервером делаем в фоне
      Connectivity().checkConnectivity().then((connectivityResult) {
        if (connectivityResult != ConnectivityResult.none) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
                'purchasedStyles': updatedStyles,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .catchError((e) {
                debugPrint('Ошибка при синхронизации покупки стиля: $e');
              });
        } else {
          debugPrint('Нет интернета, стиль куплен только локально');
        }
      });
      debugPrint('Стиль ${style.id} успешно куплен');
      return true;
    } catch (e) {
      debugPrint('Ошибка при покупке стиля ${style.id}: $e');
      return false;
    }
  }

  // Применение стиля
  Future<void> selectStyle(String styleId) async {
    try {
      if (!_boughtStyleIds.contains(styleId)) {
        debugPrint('Стиль $styleId не куплен');
        return;
      }
      final currentUser = _authService.getCurrentUserSync();
      // --- Всегда обновляем локально ---
      await CacheService.saveSelectedStyle(styleId);
      _selectedStyleId = styleId;
      notifyListeners();
      // --- Пробуем синхронизировать с сервером, если есть интернет ---
      if (currentUser != null) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .set({
                  'selectedStyle': styleId,
                  'lastUpdated': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
          } catch (e) {
            debugPrint('Ошибка при синхронизации выбранного стиля: $e');
          }
        } else {
          debugPrint('Нет интернета, стиль выбран только локально');
        }
      }
      // Обновляем тему через BuildContext
      if (navigatorKey.currentContext != null) {
        final themeProvider = Provider.of<ThemeProvider>(navigatorKey.currentContext!, listen: false);
        await themeProvider.setStyleTheme(styleId);
      }
      debugPrint('Выбран стиль $styleId');
    } catch (e) {
      debugPrint('Ошибка при обновлении выбранного стиля: $e');
    }
  }

  // Получить объект стиля по ID
  SlotStyle getStyleById(String id) {
    return _allSlotStyles.firstWhere(
      (style) => style.id == id,
      orElse: () => _allSlotStyles.first,
    );
  }

  // Проверить, куплен ли стиль
  bool isStyleBought(String styleId) {
    return _boughtStyleIds.contains(styleId);
  }

  // Метод для обновления стилей при смене пользователя
  Future<void> updateStylesForUser() async {
    if (!_isLoading) {
      _isInitialized = false;
      await _initializeStyles();
    }
  }

  Future<void> _saveBoughtStyles() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      for (final styleId in _boughtStyleIds) {
        await _authService.addPurchasedStyle(styleId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при сохранении купленных стилей: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadBoughtStyles() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final user = _authService.getCurrentUserSync();
      if (user != null) {
        _boughtStyleIds = List<String>.from(user.purchasedStyles);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке купленных стилей: $e');
    } finally {
      _isLoading = false;
    }
  }
} 