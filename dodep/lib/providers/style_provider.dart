import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'dart:async'; // Добавляем импорт для TimeoutException
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show listEquals;
import '../models/app_user.dart';
import 'theme_provider.dart';
import '../utils/global_keys.dart';

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
    SlotStyle(id: 'dresnya', name: 'Дресня', imageAsset: 'assets/images/slotstyle2.png', price: 1000),
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
        // Загружаем из локального хранилища сначала
        _loadFromLocalStorage();

        // Затем асинхронно обновляем из Firebase
        _updateFromFirebase(currentUser);
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
    try {
      final database = FirebaseDatabase.instance;
      final userSnapshot = await database
          .ref()
          .child('users/${currentUser.uid}/purchasedStyles')
          .get();

      if (userSnapshot.exists) {
        final purchasedStyles = (userSnapshot.value as List<dynamic>?)?.cast<String>() ?? [];
        if (!listEquals(purchasedStyles, _boughtStyleIds)) {
          _boughtStyleIds = purchasedStyles;
          if (!_boughtStyleIds.contains('classic')) {
            _boughtStyleIds.add('classic');
            await _authService.updateUserData(purchasedStyles: _boughtStyleIds);
          }
          await _prefs!.setStringList(_currentBoughtStylesKey, _boughtStyleIds);
        }
      }

      final selectedStyleSnapshot = await database
          .ref()
          .child('users/${currentUser.uid}/selectedStyle')
          .get();

      if (selectedStyleSnapshot.exists) {
        final selectedStyle = selectedStyleSnapshot.value as String?;
        if (selectedStyle != null && _boughtStyleIds.contains(selectedStyle) && selectedStyle != _selectedStyleId) {
          _selectedStyleId = selectedStyle;
          await _prefs!.setString(_currentSelectedStyleKey, _selectedStyleId);
        }
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении стилей из Firebase: $e');
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
    if (_boughtStyleIds.contains(style.id)) {
      debugPrint('Стиль ${style.id} уже куплен');
      return false;
    }
    
    if (style.price == null) {
      debugPrint('Стиль ${style.id} не имеет цены');
      return false;
    }

    final currentUser = _authService.getCurrentUserSync();
    if (currentUser == null) {
      debugPrint('Пользователь не авторизован');
      return false;
    }

    try {
      // Создаем новый список стилей
      final updatedStyles = List<String>.from(_boughtStyleIds)..add(style.id);
      
      // Обновляем в Firebase
      final database = FirebaseDatabase.instance;
      await database
          .ref()
          .child('users/${currentUser.uid}')
          .update({
            'purchasedStyles': updatedStyles,
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания при обновлении стилей');
            },
          );
      
      // Обновляем локальное состояние
      _boughtStyleIds = updatedStyles;
      await _prefs!.setStringList(_currentBoughtStylesKey, _boughtStyleIds);
      
      notifyListeners();
      debugPrint('Стиль ${style.id} успешно куплен и сохранен в Firebase');
      return true;
    } catch (e) {
      debugPrint('Ошибка при покупке стиля ${style.id}: $e');
      return false;
    }
  }

  // Применение стиля
  Future<void> selectStyle(String styleId) async {
    if (!_boughtStyleIds.contains(styleId)) {
      debugPrint('Стиль $styleId не куплен');
      return;
    }

    final currentUser = _authService.getCurrentUserSync();
    if (currentUser != null) {
      try {
        // Обновляем выбранный стиль в Firebase
        final database = FirebaseDatabase.instance;
        await database
            .ref()
            .child('users/${currentUser.uid}')
            .update({
              'selectedStyle': styleId,
            })
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Превышено время ожидания при обновлении выбранного стиля');
              },
            );
        
        debugPrint('Выбранный стиль $styleId сохранен в Firebase');
      } catch (e) {
        debugPrint('Ошибка при обновлении выбранного стиля в Firebase: $e');
      }
    }

    // Обновляем локальное состояние
    _selectedStyleId = styleId;
    await _prefs!.setString(_currentSelectedStyleKey, styleId);
    
    // Обновляем тему через BuildContext
    if (navigatorKey.currentContext != null) {
      final themeProvider = Provider.of<ThemeProvider>(navigatorKey.currentContext!, listen: false);
      await themeProvider.setStyleTheme(styleId);
    }
    
    notifyListeners();
    debugPrint('Выбран стиль $styleId');
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
} 