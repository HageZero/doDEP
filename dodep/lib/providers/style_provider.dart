import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _boughtStylesKey = 'bought_slot_styles';
  
  // Список всех доступных стилей слотов
  final List<SlotStyle> _allSlotStyles = const [
    SlotStyle(id: 'slotstyle1', name: 'Фентези-Гача', imageAsset: 'assets/images/slotstyle1.png'), // Начальный стиль
    SlotStyle(id: 'slotstyle2', name: 'Дресня', imageAsset: 'assets/images/slotstyle2.png', price: 1000),
    SlotStyle(id: 'slotstyle3', name: 'Токийский пук', imageAsset: 'assets/images/slotstyle3.png', price: 1500),
    SlotStyle(id: 'slotstyle4', name: 'Лего', imageAsset: 'assets/images/slotstyle4.png', price: 2000),
    SlotStyle(id: 'slotstyle5', name: 'Майнкрафт', imageAsset: 'assets/images/slotstyle5.png', price: 2500),
    SlotStyle(id: 'slotstyle6', name: 'Дока 3', imageAsset: 'assets/images/slotstyle6.png', price: 3000),
  ];

  List<String> _boughtStyleIds = ['slotstyle1']; // Список ID купленных стилей, по умолчанию есть 'slotstyle1'
  String _selectedStyleId = 'slotstyle1'; // ID текущего выбранного стиля
  SharedPreferences? _prefs;

  StyleProvider() {
    _loadStyles();
  }

  // Геттеры
  List<SlotStyle> get allSlotStyles => _allSlotStyles;
  List<String> get boughtStyleIds => _boughtStyleIds;
  String get selectedStyleId => _selectedStyleId;

  // Загрузка купленных стилей из SharedPreferences
  Future<void> _loadStyles() async {
    _prefs = await SharedPreferences.getInstance();
    final savedStyles = _prefs!.getStringList(_boughtStylesKey);
    if (savedStyles != null) {
      _boughtStyleIds = savedStyles;
    }
    // Проверяем, если выбранный стиль больше не куплен (хотя по логике такого быть не должно), сбрасываем на дефолтный
    if (!_boughtStyleIds.contains(_selectedStyleId)) {
      _selectedStyleId = 'slotstyle1';
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
    await _prefs!.setStringList(_boughtStylesKey, _boughtStyleIds);
    notifyListeners();
    return true;
  }

  // Применение стиля
  Future<void> selectStyle(String styleId) async {
    if (_boughtStyleIds.contains(styleId)) {
      _selectedStyleId = styleId;
      // Сохранять выбранный стиль не обязательно, но можно добавить если нужно сохранять между сессиями
      // await _prefs!.setString('selected_slot_style', styleId);
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
} 