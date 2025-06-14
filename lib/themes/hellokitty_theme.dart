import 'package:flutter/material.dart';

class HelloKittyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFF69B4), // Hello Kitty Pink
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFB6C1), // Light Pink
        onPrimaryContainer: Color(0xFFD72660), // Deep Pink
        secondary: Color(0xFFFFD700), // Yellow (bow)
        onSecondary: Color(0xFF333333),
        secondaryContainer: Color(0xFFFFF9C4), // Light Yellow
        onSecondaryContainer: Color(0xFFB8860B),
        tertiary: Color(0xFFB0E0E6), // Pastel Blue
        onTertiary: Color(0xFF333333),
        tertiaryContainer: Color(0xFFE0FFFF), // Light Blue
        onTertiaryContainer: Color(0xFF4682B4),
        error: Color(0xFFD72660), // Deep Pink
        onError: Colors.white,
        errorContainer: Color(0xFFFFE4E1), // Light Pink
        onErrorContainer: Color(0xFFD72660),
        background: Color(0xFFFFF8FB), // Very light pink/white
        onBackground: Color(0xFFFFB6C1),
        surface: Colors.white,
        onSurface: Color(0xFF333333),
        surfaceVariant: Color(0xFFFFE4E1), // Light Pink
        onSurfaceVariant: Color(0xFFD72660),
        outline: Color(0xFFFF69B4), // Hello Kitty Pink
        shadow: Color(0xFF000000).withOpacity(0.08),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD72660),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD72660),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFD72660),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFD700),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
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
        shadowColor: Color(0xFFFF69B4).withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFFF69B4),
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF69B4),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF69B4),
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFFD72660),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFFF69B4),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD72660),
        ),
      ),
      scaffoldBackgroundColor: Color(0xFFFFF8FB),
      dividerTheme: DividerThemeData(
        color: Color(0xFFFF69B4).withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFFF69B4),
        contentTextStyle: TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFFB6C1),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: Color(0xFF333333),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: Color(0xFFFF69B4),
              size: 24,
            );
          }
          return IconThemeData(
            color: Color(0xFF333333).withOpacity(0.7),
            size: 24,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Color(0xFFFF69B4), // Hello Kitty Pink
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD72660), // Deep Pink
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFFFFD700), // Yellow (bow)
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFB8860B),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFFB0E0E6), // Pastel Blue
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF4682B4),
        onTertiaryContainer: Colors.white,
        error: Color(0xFFFF69B4),
        onError: Colors.white,
        errorContainer: Color(0xFFD72660),
        onErrorContainer: Colors.white,
        background: Color(0xFF1A1A1A), // Darker background
        onBackground: Colors.white,
        surface: Color(0xFF2C2C2C),
        onSurface: Colors.white,
        surfaceVariant: Color(0xFFD72660),
        onSurfaceVariant: Colors.white,
        outline: Color(0xFFFF69B4),
        shadow: Color(0xFF000000).withOpacity(0.18),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFF69B4),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFD700),
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
        color: Color(0xFF2C2C2C),
        shadowColor: Color(0xFFFF69B4).withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFFF69B4),
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF69B4),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF69B4),
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF2C2C2C),
        foregroundColor: Color(0xFFFF69B4),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFFF69B4),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF69B4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        indicatorColor: Color(0xFFD72660),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: Color(0xFFFF69B4),
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: Color(0xFF1A1A1A),
      dividerTheme: DividerThemeData(
        color: Color(0xFFFF69B4).withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFD72660),
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