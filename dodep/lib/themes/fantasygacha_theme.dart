import 'package:flutter/material.dart';

class FantasyGachaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: const Color(0xFF008B8B), // Тёмный бирюзовый
        onPrimary: const Color(0xFFD4AF37), // Приглушённое золото
        secondary: const Color(0xFF006666), // Глубокий бирюзовый
        onSecondary: const Color(0xFFD4AF37),
        error: const Color(0xFF8B0000),
        onError: const Color(0xFFD4AF37),
        background: const Color(0xFFE0FFFF), // Светлый бирюзовый
        onBackground: const Color(0xFF7ACFCF),
        surface: const Color(0xFFB0E0E6), // Пороховой синий
        onSurface: const Color(0xFF2F4F4F),
        primaryContainer: const Color(0xFF20B2AA), // Светло-бирюзовый
        onPrimaryContainer: const Color(0xFFD4AF37),
        secondaryContainer: const Color(0xFF008B8B),
        onSecondaryContainer: const Color(0xFFD4AF37),
        tertiaryContainer: const Color(0xFF008B8B),
        onTertiaryContainer: const Color(0xFFD4AF37),
        surfaceVariant: const Color(0xFFE0FFFF),
        onSurfaceVariant: const Color(0xFF2F4F4F),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Color(0xFFB0E0E6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008B8B),
          foregroundColor: const Color(0xFFD4AF37),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF008B8B),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFB0E0E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF008B8B),
        contentTextStyle: TextStyle(color: Color(0xFFD4AF37)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF008B8B),
        foregroundColor: Color(0xFFD4AF37),
        elevation: 4,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2F4F4F),
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(0xFF006666), // Глубокий бирюзовый
        onPrimary: const Color(0xFFD4AF37), // Приглушённое золото
        secondary: const Color(0xFF004D4D), // Очень тёмный бирюзовый
        onSecondary: const Color(0xFFD4AF37),
        error: const Color(0xFF8B0000),
        onError: const Color(0xFFD4AF37),
        background: const Color(0xFF1A1A2E), // Тёмно-синий
        onBackground: const Color(0xFFD4AF37),
        surface: const Color(0xFF003333), // Тёмный бирюзовый
        onSurface: const Color(0xFFD4AF37),
        primaryContainer: const Color(0xFF004D4D),
        onPrimaryContainer: const Color(0xFFD4AF37),
        secondaryContainer: const Color(0xFF006666),
        onSecondaryContainer: const Color(0xFFD4AF37),
        tertiaryContainer: const Color(0xFF006666),
        onTertiaryContainer: const Color(0xFFD4AF37),
        surfaceVariant: const Color(0xFF003333),
        onSurfaceVariant: const Color(0xFFD4AF37),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Color(0xFF003333),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006666),
          foregroundColor: const Color(0xFFD4AF37),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFD4AF37),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF003333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF006666),
        contentTextStyle: TextStyle(color: Color(0xFFD4AF37)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF006666),
        foregroundColor: Color(0xFFD4AF37),
        elevation: 4,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD4AF37),
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
    );
  }
} 