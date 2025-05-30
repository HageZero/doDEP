import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/style_provider.dart';
import 'providers/language_provider.dart';
import 'theme/app_theme.dart';
import 'themes/minecraft_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BalanceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StyleProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, StyleProvider, BalanceProvider>(
      builder: (context, themeProvider, styleProvider, balanceProvider, _) {
        return MaterialApp(
          title: 'DoDep',
          theme: styleProvider.selectedStyleId == 'slotstyle5' 
              ? MinecraftTheme.lightTheme 
              : AppTheme.lightTheme,
          darkTheme: styleProvider.selectedStyleId == 'slotstyle5' 
              ? MinecraftTheme.darkTheme 
              : AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/auth': (context) => const AuthScreen(),
            '/main': (context) => const MainScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
