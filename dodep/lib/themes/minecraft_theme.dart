import 'package:flutter/material.dart';

class MinecraftTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: const Color(0xFF8B4513), // Основной цвет земли
        onPrimary: const Color(0xFFFFF8DC), // Светлый текст на темном фоне
        secondary: const Color(0xFFCD853F), // Светло-коричневый для акцентов
        onSecondary: const Color(0xFF2F1810), // Темный текст на светлом фоне
        error: const Color(0xFF8B0000), // Темно-красный
        onError: const Color(0xFFFFF8DC),
        background: const Color(0xFFF5DEB3), // Светлый песочный фон
        onBackground: const Color(0xFF2F1810),
        surface: const Color(0xFFDEB887), // Светло-коричневая поверхность
        onSurface: const Color(0xFF2F1810),
        primaryContainer: const Color(0xFFA0522D), // Контейнер цвета земли
        onPrimaryContainer: const Color(0xFFFFF8DC),
        secondaryContainer: const Color(0xFFD2691E), // Оранжево-коричневый контейнер
        onSecondaryContainer: const Color(0xFFFFF8DC),
        tertiaryContainer: const Color(0xFF8B4513), // Третичный контейнер
        onTertiaryContainer: const Color(0xFFFFF8DC),
        surfaceVariant: const Color(0xFFE6BE8A), // Вариант поверхности
        onSurfaceVariant: const Color(0xFF2F1810),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Color(0xFFDEB887),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: const Color(0xFFFFF8DC),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF8B4513),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFDEB887),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF8B4513),
        contentTextStyle: TextStyle(color: Color(0xFFFFF8DC)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Color(0xFFFFF8DC),
        elevation: 4,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5DEB3),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(0xFF5C4033), // Темный цвет земли
        onPrimary: const Color(0xFFE6D5AC), // Светлый текст
        secondary: const Color(0xFF8B7355), // Светло-коричневый
        onSecondary: const Color(0xFFE6D5AC),
        error: const Color(0xFF8B0000),
        onError: const Color(0xFFE6D5AC),
        background: const Color(0xFF2F1810), // Очень темный фон
        onBackground: const Color(0xFFE6D5AC),
        surface: const Color(0xFF3E2723), // Темная поверхность
        onSurface: const Color(0xFFE6D5AC),
        primaryContainer: const Color(0xFF4A3728), // Темный контейнер
        onPrimaryContainer: const Color(0xFFE6D5AC),
        secondaryContainer: const Color(0xFF6B4423), // Темный вторичный контейнер
        onSecondaryContainer: const Color(0xFFE6D5AC),
        tertiaryContainer: const Color(0xFF5C4033), // Темный третичный контейнер
        onTertiaryContainer: const Color(0xFFE6D5AC),
        surfaceVariant: const Color(0xFF3E2723), // Темный вариант поверхности
        onSurfaceVariant: const Color(0xFFE6D5AC),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Color(0xFF3E2723),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C4033),
          foregroundColor: const Color(0xFFE6D5AC),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFE6D5AC),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF3E2723),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF5C4033),
        contentTextStyle: TextStyle(color: Color(0xFFE6D5AC)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF5C4033),
        foregroundColor: Color(0xFFE6D5AC),
        elevation: 4,
      ),
      scaffoldBackgroundColor: const Color(0xFF2F1810),
    );
  }
} 