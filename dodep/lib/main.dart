import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'providers/theme_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/style_provider.dart';
import 'providers/language_provider.dart';
import 'theme/app_theme.dart';
import 'themes/minecraft_theme.dart';
import 'themes/yamete_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'utils/global_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  await Firebase.initializeApp(); 
  FirebaseDatabase.instance.databaseURL = 'https://dodep-afb6b-default-rtdb.europe-west1.firebasedatabase.app';
  
  // Создаем экземпляр AuthService и инициализируем его
  final authService = AuthService();
  await authService.initAuthState();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService), // AuthService должен быть первым
        ChangeNotifierProxyProvider<AuthService, BalanceProvider>(
          create: (context) => BalanceProvider(),
          update: (context, authService, previous) {
            final provider = previous ?? BalanceProvider();
            provider.updateAuthService(authService);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthService, StyleProvider>(
          create: (context) => StyleProvider(),
          update: (context, authService, previous) {
            final provider = previous ?? StyleProvider();
            provider.updateAuthService(authService);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
        ThemeData lightTheme;
        ThemeData darkTheme;

        // Выбираем тему в зависимости от стиля
        switch (styleProvider.selectedStyleId) {
          case 'minecraft':
            lightTheme = MinecraftTheme.lightTheme;
            darkTheme = MinecraftTheme.darkTheme;
            break;
          case 'yamete':
            lightTheme = YameteTheme.lightTheme;
            darkTheme = YameteTheme.darkTheme;
            break;
          default:
            lightTheme = AppTheme.lightTheme;
            darkTheme = AppTheme.darkTheme;
        }

        // Добавляем системные стили для статус бара
        lightTheme = lightTheme.copyWith(
          appBarTheme: lightTheme.appBarTheme.copyWith(
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        );

        darkTheme = darkTheme.copyWith(
          appBarTheme: darkTheme.appBarTheme.copyWith(
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        );

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'DoDep',
          theme: lightTheme,
          darkTheme: darkTheme,
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
