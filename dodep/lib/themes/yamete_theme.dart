import 'package:flutter/material.dart';

class YameteTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(0xFFE91E63), // Розовый сакуры
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFCDD2), // Светло-розовый
        onPrimaryContainer: Color(0xFF880E4F), // Темно-розовый
        secondary: Color(0xFF9C27B0), // Фиолетовый
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE1BEE7), // Светло-фиолетовый
        onSecondaryContainer: Color(0xFF4A148C), // Темно-фиолетовый
        tertiary: Color(0xFF2196F3), // Голубой
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFBBDEFB), // Светло-голубой
        onTertiaryContainer: Color(0xFF0D47A1), // Темно-голубой
        error: Color(0xFFD32F2F), // Красный
        onError: Colors.white,
        errorContainer: Color(0xFFFFEBEE), // Светло-красный
        onErrorContainer: Color(0xFFB71C1C), // Темно-красный
        background: Color(0xFFFFF5F7), // Очень светлый розовый
        onBackground: Color(0xFF1A1A1A), // Почти черный
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        surfaceVariant: Color(0xFFF3E5F5), // Светло-фиолетовый
        onSurfaceVariant: Color(0xFF4A148C), // Темно-фиолетовый
        outline: Color(0xFFE91E63), // Розовый сакуры
        shadow: Color(0xFF000000).withOpacity(0.1),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFF880E4F),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF880E4F),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF880E4F),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A148C),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4A148C),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0D47A1),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Color(0xFFE91E63).withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFE91E63), // Розовый сакуры
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFE91E63), // Розовый сакуры
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFE91E63), // Розовый сакуры
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF880E4F), // Темно-розовый
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFE91E63), // Розовый сакуры
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF880E4F), // Темно-розовый
        ),
      ),
      scaffoldBackgroundColor: Color(0xFFFFF5F7), // Очень светлый розовый
      dividerTheme: DividerThemeData(
        color: Color(0xFFE91E63).withOpacity(0.2), // Розовый сакуры с прозрачностью
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFE91E63), // Розовый сакуры
        contentTextStyle: TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFFF80AB), // Светло-розовый
        onPrimary: Color(0xFF1A1A1A), // Почти черный
        primaryContainer: Color(0xFF880E4F), // Темно-розовый
        onPrimaryContainer: Color(0xFFFFCDD2), // Светло-розовый
        secondary: Color(0xFFCE93D8), // Светло-фиолетовый
        onSecondary: Color(0xFF1A1A1A),
        secondaryContainer: Color(0xFF4A148C), // Темно-фиолетовый
        onSecondaryContainer: Color(0xFFE1BEE7), // Светло-фиолетовый
        tertiary: Color(0xFF64B5F6), // Светло-голубой
        onTertiary: Color(0xFF1A1A1A),
        tertiaryContainer: Color(0xFF0D47A1), // Темно-голубой
        onTertiaryContainer: Color(0xFFBBDEFB), // Светло-голубой
        error: Color(0xFFEF5350), // Светло-красный
        onError: Color(0xFF1A1A1A),
        errorContainer: Color(0xFFB71C1C), // Темно-красный
        onErrorContainer: Color(0xFFFFEBEE), // Светло-красный
        background: Color(0xFF1A1A1A), // Почти черный
        onBackground: Colors.white,
        surface: Color(0xFF2C2C2C), // Темно-серый
        onSurface: Colors.white,
        surfaceVariant: Color(0xFF4A148C), // Темно-фиолетовый
        onSurfaceVariant: Color(0xFFE1BEE7), // Светло-фиолетовый
        outline: Color(0xFFFF80AB), // Светло-розовый
        shadow: Color(0xFF000000).withOpacity(0.3),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFCDD2),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFCDD2),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFCDD2),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE1BEE7),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE1BEE7),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFBBDEFB),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Color(0xFF2C2C2C), // Темно-серый
        shadowColor: Color(0xFFFF80AB).withOpacity(0.3), // Светло-розовый с прозрачностью
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFFF80AB), // Светло-розовый
          foregroundColor: Color(0xFF1A1A1A), // Почти черный
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF80AB), // Светло-розовый
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF80AB), // Светло-розовый
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A), // Почти черный
        foregroundColor: Color(0xFFFFCDD2), // Светло-розовый
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFFF80AB), // Светло-розовый
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFCDD2), // Светло-розовый
        ),
      ),
      scaffoldBackgroundColor: Color(0xFF1A1A1A), // Почти черный
      dividerTheme: DividerThemeData(
        color: Color(0xFFFF80AB).withOpacity(0.2), // Светло-розовый с прозрачностью
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFF880E4F), // Темно-розовый
        contentTextStyle: TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} 