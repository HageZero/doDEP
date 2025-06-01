import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';
import '../providers/theme_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import 'main_screen.dart';
import 'auth_screen.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;
  late Animation<double> _blurAnimation;
  late List<AnimationController> _shapeControllers;
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  final List<ShapeData> _shapes = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.elasticOut,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOut,
    ));

    _dotControllers = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      Future.delayed(Duration(milliseconds: index * 200), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });

      return controller;
    });

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    _shapeControllers = List.generate(5, (index) {
      final controller = AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat();

      return controller;
    });

    _shapes.addAll([
      ShapeData(
        type: ShapeType.circle,
        size: 120,
        color: Colors.purple.withOpacity(0.1),
        position: const Offset(0.2, 0.3),
        rotation: 0,
      ),
      ShapeData(
        type: ShapeType.rectangle,
        size: 100,
        color: Colors.deepPurple.withOpacity(0.1),
        position: const Offset(0.7, 0.2),
        rotation: math.pi / 4,
      ),
      ShapeData(
        type: ShapeType.triangle,
        size: 80,
        color: Colors.indigo.withOpacity(0.1),
        position: const Offset(0.3, 0.7),
        rotation: math.pi / 6,
      ),
      ShapeData(
        type: ShapeType.hexagon,
        size: 90,
        color: Colors.blue.withOpacity(0.1),
        position: const Offset(0.8, 0.6),
        rotation: math.pi / 3,
      ),
      ShapeData(
        type: ShapeType.octagon,
        size: 70,
        color: Colors.deepPurple.withOpacity(0.1),
        position: const Offset(0.5, 0.4),
        rotation: math.pi / 2,
      ),
    ]);

    _controller.forward();
    _textAnimationController.forward();
    _initializeApp();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textAnimationController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    for (var controller in _shapeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('Начало инициализации приложения');
      final authService = Provider.of<AuthService>(context, listen: false);
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      final styleProvider = Provider.of<StyleProvider>(context, listen: false);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('[SplashScreen] Нет интернета, инициализация только локальных данных');
        await Future.wait([
          themeProvider.initialize(),
          balanceProvider.initialize(),
          styleProvider.initialize(),
        ]);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          final currentUser = authService.getCurrentUserSync();
          debugPrint('Проверка состояния пользователя (оффлайн): \\${currentUser?.username ?? 'не авторизован'}');
          if (currentUser != null) {
            debugPrint('Переход на главный экран (оффлайн)');
            Navigator.pushReplacementNamed(context, '/main');
          } else {
            debugPrint('Переход на экран авторизации (оффлайн)');
            Navigator.pushReplacementNamed(context, '/auth');
          }
        }
        return;
      }
      // --- Обычная онлайн-логика ---
      bool completed = false;
      await Future.any([
        Future(() async {
          await authService.initAuthState();
          debugPrint('[SplashScreen] _initializeApp: до syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
          int retry = 0;
          while (balanceProvider.ignoreRemoteBalanceUpdate && retry < 5) {
            debugPrint('[SplashScreen] sync/load заблокирован (ignoreRemoteBalanceUpdate=true), жду...');
            await Future.delayed(const Duration(seconds: 1));
            retry++;
          }
          if (!balanceProvider.ignoreRemoteBalanceUpdate) {
            await Future.wait([
              themeProvider.initialize(),
              balanceProvider.syncLocalOrLoadRemoteBalance(),
              styleProvider.initialize(),
            ]);
          } else {
            debugPrint('[SplashScreen] sync/load так и не разблокирован, пропускаю syncLocalOrLoadRemoteBalance');
            await Future.wait([
              themeProvider.initialize(),
              styleProvider.initialize(),
            ]);
          }
          debugPrint('[SplashScreen] _initializeApp: после syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
          await Future.delayed(const Duration(seconds: 2));
          completed = true;
          if (mounted) {
            final currentUser = authService.getCurrentUserSync();
            debugPrint('Проверка состояния пользователя: \\${currentUser?.username ?? 'не авторизован'}');
            if (currentUser != null) {
              debugPrint('Переход на главный экран');
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              debugPrint('Переход на экран авторизации');
              Navigator.pushReplacementNamed(context, '/auth');
            }
          }
        }),
        Future.delayed(const Duration(seconds: 5)),
      ]);
      if (!completed && mounted) {
        debugPrint('[SplashScreen] Таймаут! Принудительный переход по локальным данным');
        final currentUser = authService.getCurrentUserSync();
        if (currentUser != null) {
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      debugPrint('Ошибка при инициализации приложения: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _dotAnimations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3 + (_dotAnimations[index].value * 0.7)),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildShape(ShapeData shape, AnimationController controller) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final position = Offset(
          shape.position.dx * screenSize.width,
          shape.position.dy * screenSize.height,
        );

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.rotate(
            angle: shape.rotation + (controller.value * math.pi * 2),
            child: Transform.scale(
              scale: 1.0 + (math.sin(controller.value * math.pi * 2) * 0.1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    width: shape.size,
                    height: shape.size,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    debugPrint('[SplashScreen] build: текущий баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Фоновый градиент
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ] : [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.25),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Анимированные фигуры
          ...List.generate(_shapes.length, (index) {
            return _buildShape(_shapes[index], _shapeControllers[index]);
          }),
          // Основной контент
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 180,
                            height: 180,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _textAnimationController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, _textSlideAnimation.value),
                                        child: Opacity(
                                          opacity: _textOpacityAnimation.value,
                                          child: Transform.scale(
                                            scale: _textScaleAnimation.value,
                                            child: Text(
                                              'Депаем шекели...',
                                              style: TextStyle(
                                                color: isDark 
                                                    ? Colors.white.withOpacity(0.9)
                                                    : Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                          fontSize: 28,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                                shadows: [
                                                  Shadow(
                                                    color: isDark 
                                                        ? Colors.black.withOpacity(0.3)
                                                        : Colors.white.withOpacity(0.3),
                                                    offset: const Offset(0, 2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 24),
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                isDark 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                BlendMode.srcIn,
                              ),
                              child: Lottie.asset(
                                'assets/loading.json',
                                width: 140,
                                height: 80,
                                fit: BoxFit.contain,
                                repeat: true,
                                animate: true,
                                filterQuality: FilterQuality.high,
                                options: LottieOptions(
                                  enableMergePaths: true,
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateSystemUI() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final backgroundColor = Theme.of(context).colorScheme.background;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeProvider.isDarkMode 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarDividerColor: backgroundColor,
        systemNavigationBarIconBrightness: themeProvider.isDarkMode 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }
}

enum ShapeType {
  circle,
  rectangle,
  triangle,
  hexagon,
  octagon,
}

class ShapeData {
  final ShapeType type;
  final double size;
  final Color color;
  final Offset position;
  final double rotation;

  ShapeData({
    required this.type,
    required this.size,
    required this.color,
    required this.position,
    required this.rotation,
  });
} 