import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

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
    SlotStyle(id: 'fantasy_gacha', name: 'Фэнтези-гача', imageAsset: 'assets/images/slotstyle1.png', price: 3000),
    SlotStyle(id: 'slotstyle2', name: 'Дресня', imageAsset: 'assets/images/slotstyle2.png', price: 1000),
    SlotStyle(id: 'slotstyle3', name: 'Токийский пук', imageAsset: 'assets/images/slotstyle3.png', price: 4500),
    SlotStyle(id: 'slotstyle4', name: 'Лего', imageAsset: 'assets/images/slotstyle4.png', price: 6000),
    SlotStyle(id: 'slotstyle5', name: 'Майнкрафт', imageAsset: 'assets/images/minecraft.jpg', price: 3800),
    SlotStyle(id: 'slotstyle6', name: 'Дока 3', imageAsset: 'assets/images/slotstyle6.png', price: 7000),
  ];

  List<String> _boughtStyleIds = ['classic']; // Список ID купленных стилей, по умолчанию есть 'classic'
  String _selectedStyleId = 'classic'; // ID текущего выбранного стиля
  SharedPreferences? _prefs;
  final AuthService _authService = AuthService();

  StyleProvider() {
    _loadStyles();
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
    await _loadStyles();
  }

  // Загрузка купленных стилей из SharedPreferences
  Future<void> _loadStyles() async {
    _prefs = await SharedPreferences.getInstance();
    final savedStyles = _prefs!.getStringList(_currentBoughtStylesKey);
    if (savedStyles != null) {
      _boughtStyleIds = savedStyles;
    } else {
      _boughtStyleIds = ['classic']; // Сброс к дефолтному значению для нового пользователя
    }
    
    // Загружаем выбранный стиль
    final savedSelectedStyle = _prefs!.getString(_currentSelectedStyleKey);
    if (savedSelectedStyle != null && _boughtStyleIds.contains(savedSelectedStyle)) {
      _selectedStyleId = savedSelectedStyle;
    } else {
      _selectedStyleId = 'classic';
    }
    
    notifyListeners();
  }

  // Покупка стиля
  Future<bool> buyStyle(SlotStyle style) async {
    if (_boughtStyleIds.contains(style.id)) {
      // Стиль уже куплен
      return false;
    }
    if (style.price == null) {
       // Нельзя купить стиль без цены (например, дефолтный)
       return false;
    }

    // Здесь должна быть проверка баланса и его списание (это будет в ShopScreen)
    // Если покупка успешна:
    _boughtStyleIds.add(style.id);
    await _prefs!.setStringList(_currentBoughtStylesKey, _boughtStyleIds);
    notifyListeners();
    return true;
  }

  // Применение стиля
  Future<void> selectStyle(String styleId) async {
    if (_boughtStyleIds.contains(styleId)) {
      _selectedStyleId = styleId;
      await _prefs!.setString(_currentSelectedStyleKey, styleId);
      notifyListeners();
    }
  }

  // Получить объект стиля по ID
  SlotStyle getStyleById(String id) {
    return _allSlotStyles.firstWhere((style) => style.id == id, orElse: () => _allSlotStyles.first);
  }

  // Проверить, куплен ли стиль
  bool isStyleBought(String styleId) {
    return _boughtStyleIds.contains(styleId);
  }

  // Метод для обновления стилей при смене пользователя
  Future<void> updateStylesForUser() async {
    await _loadStyles();
  }
} 