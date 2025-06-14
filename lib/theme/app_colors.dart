import 'package:flutter/material.dart';

class AppColors {
  // Основные цвета
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFFF6B6B); // Коралловый
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF2D3142); // Тёмно-синий
  static const Color textLight = Color(0xFF9C9EB9); // Серо-синий
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onBackground = Color(0xFF000000);
  static const Color onSurface = Color(0xFF000000);

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D9F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Светлая тема
  static const Color lightPrimary = Color(0xFFF48FB1); // Light Pink
  static const Color lightSecondary = Color(0xFFF8BBD0); // Lighter Pink
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFCE4EC); // Very light pink
  static const Color lightOnPrimary = Color(0xFF000000);
  static const Color lightOnSecondary = Color(0xFF000000);
  static const Color lightOnBackground = Color(0xFF262626); // Dark grey for text
  static const Color lightOnSurface = Color(0xFF000000);

  // Темная тема
  static const Color darkPrimary = Color(0xFF4A148C); // Dark Purple
  static const Color darkSecondary = Color(0xFF6A1B9A); // Slightly lighter Purple
  static const Color darkBackground = Color(0xFF121212); // Very dark grey
  static const Color darkSurface = Color(0xFF212121); // Dark grey
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSecondary = Color(0xFFFFFFFF);
  static const Color darkOnBackground = Color(0xFFE0E0E0); // Light grey for text
  static const Color darkOnSurface = Color(0xFFE0E0E0);

  static ColorScheme get lightColorScheme {
    return const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      background: lightBackground,
      surface: lightSurface,
      onPrimary: lightOnPrimary,
      onSecondary: lightOnSecondary,
      onBackground: lightOnBackground,
      onSurface: lightOnSurface,
    );
  }

  static ColorScheme get darkColorScheme {
    return const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      background: darkBackground,
      surface: darkSurface,
      onPrimary: darkOnPrimary,
      onSecondary: darkOnSecondary,
      onBackground: darkOnBackground,
      onSurface: darkOnSurface,
    );
  }

  // Дополнительные цвета для UI элементов
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  // Цвета для теней и границ
  static const Color shadow = Color(0x1A000000);
  static const Color border = Color(0xFFE0E0E0);

  // Градиенты (опционально, для элементов UI)
  static const LinearGradient instagramGradient = LinearGradient(
    colors: [
      Color(0xFFFD1D1D), // red
      Color(0xFFE1306C), // pink
      Color(0xFFC13584), // purple
      Color(0xFF833AB4), // purple deep
      Color(0xFF405DE6), // blue
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
} 