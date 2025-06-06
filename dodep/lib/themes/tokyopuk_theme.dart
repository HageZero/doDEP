import 'package:flutter/material.dart';

class TokyoGhoulTheme {
  // Основные цвета Tokyo Ghoul
  static const Color bloodRed = Color(0xFFE31B23); // Цвет крови
  static const Color darkBlood = Color(0xFF8B0000); // Темный красный
  static const Color kaguneBlack = Color(0xFF1A1A1A); // Цвет кагуне
  static const Color maskWhite = Color(0xFFF5F5F5); // Цвет маски
  static const Color ghoulEye = Color(0xFFE31B23); // Красный цвет глаз гуля
  static const Color investigatorEye = Color(0xFF4169E1); // Синий цвет глаз следователя
  static const Color kaguneRed = Color(0xFFB22222); // Цвет кагуне в активном состоянии
  static const Color quinqueBlue = Color(0xFF1E90FF); // Цвет квинке
  static const Color investigatorBlack = Color(0xFF2F4F4F); // Цвет формы следователя
  static const Color ghoulPurple = Color(0xFF800080); // Фиолетовый цвет для особых гулей
  static const Color lightBackground = Color(0xFFF8F8F8); // Светлый фон
  static const Color darkBackground = Color(0xFF121212); // Темный фон
  static const Color lightSurface = Color(0xFFFFFFFF); // Светлая поверхность
  static const Color darkSurface = Color(0xFF1E1E1E); // Темная поверхность

  // Градиенты для навигационной панели
  static const LinearGradient lightNavGradient = LinearGradient(
    colors: [kaguneRed, bloodRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkNavGradient = LinearGradient(
    colors: [ghoulEye, darkBlood],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: kaguneRed,
        onPrimary: maskWhite,
        secondary: ghoulEye,
        onSecondary: maskWhite,
        error: darkBlood,
        onError: maskWhite,
        background: lightBackground,
        onBackground: kaguneBlack,
        surface: lightSurface,
        onSurface: kaguneBlack,
        primaryContainer: kaguneRed.withOpacity(0.1),
        onPrimaryContainer: kaguneRed,
        secondaryContainer: ghoulEye.withOpacity(0.1),
        onSecondaryContainer: ghoulEye,
        tertiaryContainer: investigatorEye.withOpacity(0.1),
        onTertiaryContainer: investigatorEye,
        surfaceVariant: Colors.grey[100]!,
        onSurfaceVariant: Colors.grey[800]!,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kaguneRed,
          foregroundColor: maskWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kaguneRed,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kaguneRed,
        contentTextStyle: const TextStyle(color: maskWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kaguneRed,
        foregroundColor: maskWhite,
        elevation: 4,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kaguneRed),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kaguneRed),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kaguneRed),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kaguneRed),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kaguneRed),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kaguneRed),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kaguneBlack),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kaguneBlack),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kaguneBlack),
        bodyLarge: TextStyle(fontSize: 16, color: kaguneBlack),
        bodyMedium: TextStyle(fontSize: 14, color: kaguneBlack),
        bodySmall: TextStyle(fontSize: 12, color: kaguneBlack),
      ),
      scaffoldBackgroundColor: lightBackground,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: kaguneRed.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            color: kaguneRed,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: kaguneRed);
          }
          return IconThemeData(color: Colors.grey[600]);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: ghoulEye,
        onPrimary: maskWhite,
        secondary: kaguneRed,
        onSecondary: maskWhite,
        error: darkBlood,
        onError: maskWhite,
        background: darkBackground,
        onBackground: maskWhite,
        surface: darkSurface,
        onSurface: maskWhite,
        primaryContainer: ghoulEye.withOpacity(0.2),
        onPrimaryContainer: ghoulEye,
        secondaryContainer: kaguneRed.withOpacity(0.2),
        onSecondaryContainer: kaguneRed,
        tertiaryContainer: quinqueBlue.withOpacity(0.2),
        onTertiaryContainer: quinqueBlue,
        surfaceVariant: Color(0xFF2A2A2A),
        onSurfaceVariant: Colors.grey[300]!,
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: darkSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ghoulEye,
          foregroundColor: maskWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ghoulEye,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ghoulEye,
        contentTextStyle: const TextStyle(color: maskWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: ghoulEye,
        elevation: 4,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ghoulEye),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ghoulEye),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ghoulEye),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: ghoulEye),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: ghoulEye),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ghoulEye),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: maskWhite),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: maskWhite),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: maskWhite),
        bodyLarge: TextStyle(fontSize: 16, color: maskWhite),
        bodyMedium: TextStyle(fontSize: 14, color: maskWhite),
        bodySmall: TextStyle(fontSize: 12, color: maskWhite),
      ),
      scaffoldBackgroundColor: darkBackground,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: ghoulEye.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            color: ghoulEye,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: ghoulEye);
          }
          return IconThemeData(color: Colors.grey[400]);
        }),
      ),
    );
  }
} 