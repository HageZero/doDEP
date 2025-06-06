import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/theme_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/style_provider.dart';
import 'providers/language_provider.dart';
import 'providers/quests_provider.dart';
import 'theme/app_theme.dart';
import 'themes/minecraft_theme.dart';
import 'themes/yamete_theme.dart';
import 'themes/hellokitty_theme.dart';
import 'themes/dresnya_theme.dart';
import 'themes/doka3_theme.dart';
import 'themes/lego_theme.dart';
import 'themes/tokyopuk_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'utils/global_keys.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);
  await Hive.openBox<int>('balances');

  // Инициализация Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBTMb63N7KoAN6_AJfVmiBJO1qMprMp-pc",
      appId: "1:279751409016:android:60753aecbdbf75a0699c8d",
      messagingSenderId: "279751409016",
      projectId: "dodep-afb6b",
      storageBucket: "dodep-afb6b.firebasestorage.app",
      databaseURL: "https://dodep-afb6b-default-rtdb.europe-west1.firebasedatabase.app",
    ),
  );

  // Настройка Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Тестовый код для проверки Firestore
  try {
    debugPrint('Проверка коллекции users:');
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in usersSnapshot.docs) {
      debugPrint('Документ пользователя: ${doc.id}');
      debugPrint('Данные: ${doc.data()}');
    }

    debugPrint('\nПроверка коллекции usernames:');
    final usernamesSnapshot = await FirebaseFirestore.instance.collection('usernames').get();
    for (var doc in usernamesSnapshot.docs) {
      debugPrint('Документ username: ${doc.id}');
      debugPrint('Данные: ${doc.data()}');
    }
  } catch (e) {
    debugPrint('Ошибка при проверке Firestore: $e');
  }
  
  // Создаем экземпляр AuthService и инициализируем его
  final authService = AuthService();
  await authService.initAuthState();
  
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProxyProvider<AuthService, BalanceProvider>(
          create: (context) => BalanceProvider(authService),
          update: (context, authService, previous) {
            if (previous == null) {
              return BalanceProvider(authService);
            }
            return previous;
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
        ChangeNotifierProvider(create: (_) => QuestsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _noDepTimer;
  int? _lastBalance;
  AudioPlayer? _noDepAudioPlayer;
  DateTime? _lastBalanceChange;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final balanceProvider = Provider.of<BalanceProvider>(context);
    balanceProvider.removeListener(_onBalanceChanged); // avoid duplicate listeners
    balanceProvider.addListener(_onBalanceChanged);
    _onBalanceChanged(); // initial check
  }

  void _onBalanceChanged() {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final balance = balanceProvider.balance;
    if (_lastBalance != balance) {
      _lastBalanceChange = DateTime.now();
      _lastBalance = balance;
      _noDepTimer?.cancel();
      _noDepAudioPlayer?.stop();
      if (balance == 0) {
        _noDepTimer = Timer(const Duration(seconds: 90), () {
          final now = DateTime.now();
          if (balanceProvider.balance == 0 && _lastBalanceChange != null && now.difference(_lastBalanceChange!) >= const Duration(seconds: 90)) {
            _noDepAudioPlayer?.stop();
            _noDepAudioPlayer = AudioPlayer();
            _noDepAudioPlayer!.play(AssetSource('sounds/nodep.mp3'));
          }
        });
      }
    }
    // Если баланс 0 и таймер не запущен (например, при старте)
    if (balance == 0 && _noDepTimer == null) {
      _noDepTimer = Timer(const Duration(seconds: 90), () {
        final now = DateTime.now();
        if (balanceProvider.balance == 0 && _lastBalanceChange != null && now.difference(_lastBalanceChange!) >= const Duration(seconds: 90)) {
          _noDepAudioPlayer?.stop();
          _noDepAudioPlayer = AudioPlayer();
          _noDepAudioPlayer!.play(AssetSource('sounds/nodep.mp3'));
        }
      });
    }
    // Если баланс > 0, сбрасываем всё
    if (balance > 0) {
      _noDepTimer?.cancel();
      _noDepTimer = null;
      _noDepAudioPlayer?.stop();
    }
  }

  @override
  void dispose() {
    _noDepTimer?.cancel();
    _noDepAudioPlayer?.stop();
    _noDepAudioPlayer?.dispose();
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    balanceProvider.removeListener(_onBalanceChanged);
    super.dispose();
  }

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
          case 'hellokitty':
            lightTheme = HelloKittyTheme.lightTheme;
            darkTheme = HelloKittyTheme.darkTheme;
            break;
          case 'dresnya':
            lightTheme = DresnyaTheme.lightTheme;
            darkTheme = DresnyaTheme.darkTheme;
            break;
          case 'doka3':
            lightTheme = Doka3Theme.lightTheme;
            darkTheme = Doka3Theme.darkTheme;
            break;
          case 'lego':
            lightTheme = LegoTheme.lightTheme;
            darkTheme = LegoTheme.darkTheme;
            break;
          case 'tokyopuk':
            lightTheme = TokyoGhoulTheme.lightTheme;
            darkTheme = TokyoGhoulTheme.darkTheme;
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
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: lightTheme.colorScheme.surface,
            indicatorColor: lightTheme.colorScheme.primaryContainer,
            labelTextStyle: MaterialStateProperty.all(
              TextStyle(
                color: lightTheme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(
                  color: lightTheme.colorScheme.primary,
                  size: 24,
                );
              }
              return IconThemeData(
                color: lightTheme.colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              );
            }),
          ),
        );

        darkTheme = darkTheme.copyWith(
          appBarTheme: darkTheme.appBarTheme.copyWith(
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: darkTheme.colorScheme.surface,
            indicatorColor: darkTheme.colorScheme.primaryContainer,
            labelTextStyle: MaterialStateProperty.all(
              TextStyle(
                color: darkTheme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return IconThemeData(
                  color: darkTheme.colorScheme.primary,
                  size: 24,
                );
              }
              return IconThemeData(
                color: darkTheme.colorScheme.onSurface.withOpacity(0.7),
                size: 24,
              );
            }),
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
