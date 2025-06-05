import 'package:flutter/material.dart';

class LegoTheme {
  // Lego color palette
  static const Color legoRed = Color(0xFFE31837); // Классический красный Lego
  static const Color legoYellow = Color(0xFFFFD700); // Желтый Lego
  static const Color legoBlue = Color(0xFF0055BF); // Синий Lego
  static const Color legoLightBlue = Color(0xFF71C5CF); // Светло-синий Lego
  static const Color legoDarkBlue = Color(0xFF003B75); // Темно-синий Lego
  static const Color legoGray = Color(0xFFA0A0A0); // Серый Lego
  static const Color legoLightGray = Color(0xFFD3D3D3); // Светло-серый Lego
  static const Color legoDarkGray = Color(0xFF4A4A4A); // Темно-серый Lego
  static const Color legoGreen = Color(0xFF237D26); // Зеленый Lego
  static const Color legoOrange = Color(0xFFFF6D00); // Оранжевый Lego

  // Градиенты для навигационного бара
  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFE31837), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0055BF), Color(0xFF71C5CF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: legoRed,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFEBEE),
        onPrimaryContainer: legoDarkBlue,
        secondary: legoOrange,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFF3E0),
        onSecondaryContainer: legoDarkBlue,
        tertiary: legoGreen,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE8F5E9),
        onTertiaryContainer: legoDarkBlue,
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: Color(0xFFB71C1C),
        background: Color(0xFFF8F9FA),
        onBackground: legoDarkBlue,
        surface: Colors.white,
        onSurface: legoDarkBlue,
        surfaceVariant: Color(0xFFF1F3F4),
        onSurfaceVariant: legoGray,
        outline: legoRed.withOpacity(0.5),
        shadow: Color(0xFF000000).withOpacity(0.1),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: legoRed),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: legoRed),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: legoRed),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: legoGreen),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: legoGreen),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: legoGreen),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: legoDarkBlue),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: legoDarkBlue),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: legoDarkBlue),
        bodyLarge: TextStyle(fontSize: 16, color: legoDarkBlue),
        bodyMedium: TextStyle(fontSize: 14, color: legoDarkBlue),
        bodySmall: TextStyle(fontSize: 12, color: legoDarkBlue),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        shadowColor: legoRed.withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: legoRed,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: legoGreen,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: legoRed,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: legoRed,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: legoRed,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: legoRed,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: legoDarkBlue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: legoRed,
              size: 24,
            );
          }
          return IconThemeData(
            color: legoGray,
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: Color(0xFFF8F9FA),
      dividerTheme: DividerThemeData(
        color: legoRed.withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: legoRed,
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
        primary: legoBlue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1A237E),
        onPrimaryContainer: Color(0xFFE3F2FD),
        secondary: legoLightBlue,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF0D47A1),
        onSecondaryContainer: Color(0xFFE3F2FD),
        tertiary: legoRed,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF4A1F1A),
        onTertiaryContainer: Color(0xFFFFEBEE),
        error: Color(0xFFEF5350),
        onError: Colors.white,
        errorContainer: Color(0xFF4A1F1A),
        onErrorContainer: Color(0xFFFFEBEE),
        background: Color(0xFF121212),
        onBackground: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        surfaceVariant: Color(0xFF2C2C2C),
        onSurfaceVariant: legoLightGray,
        outline: legoBlue.withOpacity(0.5),
        shadow: Color(0xFF000000).withOpacity(0.2),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: legoLightBlue),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: legoLightBlue),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: legoLightBlue),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: legoBlue),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: legoBlue),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: legoBlue),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: legoLightBlue),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: legoLightBlue),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: legoLightBlue),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Color(0xFF1E1E1E),
        shadowColor: legoBlue.withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: legoBlue,
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: legoLightBlue,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: legoLightBlue,
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: legoLightBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: legoLightBlue,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: legoLightBlue,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        indicatorColor: Colors.transparent,
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
              color: legoLightBlue,
              size: 24,
            );
          }
          return IconThemeData(
            color: Colors.white.withOpacity(0.7),
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: Color(0xFF121212),
      dividerTheme: DividerThemeData(
        color: legoBlue.withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: legoBlue,
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