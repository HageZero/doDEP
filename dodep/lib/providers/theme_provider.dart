import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/yamete_theme.dart';
import '../themes/hellokitty_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  static const String _styleThemeKey = 'style_theme';
  bool _isDarkMode = false;
  String _currentStyleTheme = 'default';

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;
  String get currentStyleTheme => _currentStyleTheme;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme {
    if (_currentStyleTheme == 'yamete') {
      return _isDarkMode ? YameteTheme.darkTheme : YameteTheme.lightTheme;
    }
    if (_currentStyleTheme == 'hellokitty') {
      return _isDarkMode ? HelloKittyTheme.darkTheme : HelloKittyTheme.lightTheme;
    }
    // Возвращаем стандартную тему для других стилей
    return _isDarkMode ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  }

  Future<void> initialize() async {
    await _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _currentStyleTheme = prefs.getString(_styleThemeKey) ?? 'default';
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке темы: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при переключении темы: $e');
    }
  }

  Future<void> setStyleTheme(String styleId) async {
    try {
      if (styleId == 'yamete') {
        _currentStyleTheme = 'yamete';
      } else if (styleId == 'hellokitty') {
        _currentStyleTheme = 'hellokitty';
      } else {
        _currentStyleTheme = 'default';
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_styleThemeKey, _currentStyleTheme);
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при установке стиля темы: $e');
    }
  }
} 