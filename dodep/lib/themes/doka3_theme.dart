import 'package:flutter/material.dart';

class Doka3Theme {
  // Dota 2 color palette
  static const Color dotaRed = Color(0xFFC23C2A); // Radiant red
  static const Color dotaDarkRed = Color(0xFF8B0000); // Dark red
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

  // Градиенты для навигационного бара
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFF66C0F4), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFC23C2A), Color(0xFF8B0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: dotaRadiantLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE8F5E9),
        onPrimaryContainer: dotaDarkGreen,
        secondary: dotaRadiantGold,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFF8E1),
        onSecondaryContainer: dotaDarkGold,
        tertiary: dotaGray,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE0E0E0),
        onTertiaryContainer: dotaGray,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: Color(0xFFB71C1C),
        background: Colors.white,
        onBackground: dotaDarkGray,
        surface: Color(0xFFF5F5F5),
        onSurface: dotaDarkGray,
        surfaceVariant: Color(0xFFEEEEEE),
        onSurfaceVariant: dotaGray,
        outline: dotaRadiantLight.withOpacity(0.5),
        shadow: Color(0xFF000000).withOpacity(0.1),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: dotaRadiantGold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: dotaRadiantGold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: dotaRadiantGold),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: dotaRadiantLight),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: dotaRadiantLight),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: dotaRadiantLight),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: dotaGold),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dotaGold),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dotaGold),
        bodyLarge: TextStyle(fontSize: 16, color: dotaDarkGray),
        bodyMedium: TextStyle(fontSize: 14, color: dotaDarkGray),
        bodySmall: TextStyle(fontSize: 12, color: dotaDarkGray),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: dotaRadiantLight.withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: dotaRadiantLight,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dotaRadiantLight,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: dotaRadiantLight,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: dotaRadiantGold,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: dotaRadiantLight,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dotaRadiantGold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dotaMenuGray,
        indicatorColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: dotaRadiantGold,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: dotaRadiantLight,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: Colors.white,
      dividerTheme: DividerThemeData(
        color: dotaRadiantLight.withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dotaRadiantLight,
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
        primary: dotaRed,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF4A1F1A),
        onPrimaryContainer: Color(0xFFFFE4E1),
        secondary: dotaGold,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF4A3F2A),
        onSecondaryContainer: dotaLightGold,
        tertiary: dotaLightGray,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF2A2A2A),
        onTertiaryContainer: dotaLightGray,
        error: Color(0xFFEF5350),
        onError: Colors.white,
        errorContainer: Color(0xFF4A1F1A),
        onErrorContainer: Color(0xFFFFCDD2),
        background: dotaDarkGray,
        onBackground: Colors.white,
        surface: dotaMenuGray,
        onSurface: Colors.white,
        surfaceVariant: Color(0xFF1B1B1B),
        onSurfaceVariant: dotaLightGray,
        outline: dotaRed.withOpacity(0.5),
        shadow: Color(0xFF000000).withOpacity(0.2),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: dotaGold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: dotaGold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: dotaGold),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: dotaLightGold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: dotaLightGold),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: dotaLightGold),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: dotaGold),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: dotaGold),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dotaGold),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: dotaMenuGray,
        shadowColor: dotaRed.withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: dotaRed,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dotaRed,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: dotaRed,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dotaDarkGray,
        foregroundColor: dotaGold,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: dotaRed,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: dotaGold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dotaMenuGray,
        indicatorColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: dotaGold,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: dotaRed,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: dotaDarkGray,
      dividerTheme: DividerThemeData(
        color: dotaRed.withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dotaRed,
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