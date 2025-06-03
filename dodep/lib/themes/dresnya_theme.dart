import 'package:flutter/material.dart';

class DresnyaTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: Color(0xFFFF5722), // Яркий оранжевый
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFAB91), // Светлый оранжевый
        onPrimaryContainer: Color(0xFFBF360C), // Темный оранжевый
        secondary: Color(0xFFFF9800), // Оранжевый
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFE0B2), // Светлый оранжевый
        onSecondaryContainer: Color(0xFFE65100),
        tertiary: Color(0xFFFFB74D), // Светлый оранжевый
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFFE0B2),
        onTertiaryContainer: Color(0xFFE65100),
        error: Color(0xFFD32F2F),
        onError: Colors.white,
        errorContainer: Color(0xFFFFCDD2),
        onErrorContainer: Color(0xFFB71C1C),
        background: Color(0xFFFFF8F3), // Очень светлый оранжевый
        onBackground: Color(0xFF1A1A1A),
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        surfaceVariant: Color(0xFFFFE0B2),
        onSurfaceVariant: Color(0xFFE65100),
        outline: Color(0xFFFF5722),
        shadow: Color(0xFF000000).withOpacity(0.08),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFFF5722)),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFFF5722)),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFFF5722)),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFF9800)),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFF9800)),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF9800)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Color(0xFFFF5722).withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFFF5722),
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF5722),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF5722),
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFFE65100),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFFF5722),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE65100),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFFAB91),
        labelTextStyle: MaterialStateProperty.all(
          TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(
              color: Color(0xFFFF5722),
              size: 24,
            );
          }
          return IconThemeData(
            color: Color(0xFF1A1A1A).withOpacity(0.7),
            size: 24,
          );
        }),
      ),
      scaffoldBackgroundColor: Color(0xFFFFF8F3),
      dividerTheme: DividerThemeData(
        color: Color(0xFFFF5722).withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFFF5722),
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
        primary: Color(0xFFFF5722), // Яркий оранжевый
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE65100), // Темный оранжевый
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFFFF9800), // Оранжевый
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE65100),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFFFFB74D), // Светлый оранжевый
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFE65100),
        onTertiaryContainer: Colors.white,
        error: Color(0xFFFF5722),
        onError: Colors.white,
        errorContainer: Color(0xFFE65100),
        onErrorContainer: Colors.white,
        background: Color(0xFF121212), // Более темный фон
        onBackground: Colors.white,
        surface: Color(0xFF1E1E1E), // Более темная поверхность
        onSurface: Colors.white,
        surfaceVariant: Color(0xFF2C2C2C), // Более темный вариант поверхности
        onSurfaceVariant: Colors.white,
        outline: Color(0xFFFF5722),
        shadow: Color(0xFF000000).withOpacity(0.18),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF8A65)),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF8A65)),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFF8A65)),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFFFFAB91)),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFFFAB91)),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFFFAB91)),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFFFCC80)),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFFCC80)),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFFCC80)),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.95)),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.95)),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.95)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Color(0xFF2C2C2C),
        shadowColor: Color(0xFFFF5722).withOpacity(0.15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFFFF5722),
          foregroundColor: Colors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFFFF5722),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: Color(0xFFFF5722),
        size: 24,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFFF5722),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color(0xFFFF5722),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF5722),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        indicatorColor: Color(0xFFE65100),
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
              color: Color(0xFFFF5722),
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
        color: Color(0xFFFF5722).withOpacity(0.15),
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color(0xFFE65100),
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