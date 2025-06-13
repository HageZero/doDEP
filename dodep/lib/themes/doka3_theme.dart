import 'package:flutter/material.dart';

class Doka3Theme {
  // Dota 2 color palette
  static const Color dotaRed = Color(0xFFC23C2A); // Radiant red
  static const Color dotaDarkRed = Color(0xFF8700); // Dark red
  static const Color dotaGreen = Color(0xFF4CAF50); // Light green
  static const Color dotaLightGreen = Color(0xFF81C784); // Lighter green
  static const Color dotaDarkGreen = Color(0xFF2E7D32); // Dark green
  static const Color dotaGold = Color(0xFFCDA434); // Dota 2 gold
  static const Color dotaLightGold = Color(0xFFE6C35C); // Light gold
  static const Color dotaDarkGold = Color(0xFF8B7355); // Dark gold
  static const Color dotaGray = Color(0xFF424242); // Menu gray
  static const Color dotaLightGray = Color(0xFF757575); // Light gray
  static const Color dotaDarkGray = Color(0xFF212121); // Dark background
  static const Color dotaMenuGray = Color(0xFF2A2A2A); // Dota 2 menu gray
  static const Color dotaRadiantGold = Color(0xFFFFD700); // Radiant gold
  static const Color dotaRadiantLight = Color(0xFF66C0F4); // Radiant light blue

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: dotaGreen,
        onPrimary: Colors.white,
        secondary: dotaRadiantGold,
        onSecondary: Colors.white,
        error: dotaRed,
        onError: Colors.white,
        background: Colors.white,
        onBackground: dotaLightGreen,
        surface: Colors.grey[700]!,
        onSurface: dotaDarkGray,
        primaryContainer: dotaGreen,
        onPrimaryContainer: Colors.white,
        secondaryContainer: dotaRadiantGold,
        onSecondaryContainer: Colors.white,
        tertiaryContainer: dotaLightGreen,
        onTertiaryContainer: Colors.white,
        surfaceVariant: Colors.grey[700]!,
        onSurfaceVariant: Colors.grey[700]!,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dotaGreen,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dotaGreen,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dotaGreen,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: dotaGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: dotaGreen,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: dotaGreen,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: dotaGreen,
        ),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dotaGreen),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: dotaGreen,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: dotaGreen,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: dotaDarkGray,
        ),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dotaDarkGray),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: dotaDarkGray),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: dotaDarkGray,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: dotaDarkGray,
        ),
        bodySmall: TextStyle(fontSize: 12, color: dotaDarkGray),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: dotaDarkGray,
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: dotaRed,
        onPrimary: Colors.white,
        secondary: dotaGold,
        onSecondary: Colors.white,
        error: dotaDarkRed,
        onError: Colors.white,
        background: dotaDarkGray,
        onBackground: Colors.white,
        surface: dotaMenuGray,
        onSurface: Colors.white,
        primaryContainer: dotaRed.withOpacity(0.2),
        onPrimaryContainer: dotaRed,
        secondaryContainer: dotaGold.withOpacity(0.2),
        onSecondaryContainer: dotaGold,
        tertiaryContainer: dotaDarkRed.withOpacity(0.2),
        onTertiaryContainer: dotaDarkRed,
        surfaceVariant: Color(0xFF2A2A2A),
        onSurfaceVariant: Colors.grey[700]!,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: dotaMenuGray,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dotaRed,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dotaRed,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: dotaMenuGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dotaRed,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: dotaDarkGray,
        foregroundColor: dotaRed,
        elevation: 4,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: dotaRed,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: dotaRed,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: dotaRed,
        ),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dotaRed),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: dotaRed,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: dotaRed,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
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
        bodySmall: TextStyle(fontSize: 12, color: Colors.white),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ).apply(
        fontFamily: 'Inter',
      ),
      scaffoldBackgroundColor: dotaDarkGray,
    );
  }
} 