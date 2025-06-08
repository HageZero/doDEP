import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/app_scaffold.dart';
import 'play_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';
import 'style_screen.dart';
import 'profile_screen.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late PageController _pageController;
  late VideoPlayerController _videoController;
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;

  late final List<Widget> _screens;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ShopScreen(),
      const PlayScreen(),
      const StyleScreen(),
      const ProfileScreen(),
    ];

    _pageController = PageController(initialPage: _selectedIndex);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _textScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutBack,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeIn,
    ));

    _videoController = VideoPlayerController.asset('assets/videos/english.mp4');
    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _videoController.setVolume(5.0);
      }
    });

    // Добавляем слушатель окончания видео
    _videoController.addListener(() {
      if (_videoController.value.position >= _videoController.value.duration) {
        Provider.of<LanguageProvider>(context, listen: false).hideVideo();
        _videoController.pause();
        _videoController.seekTo(Duration.zero);
      }
    });

    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
      if (!_isOffline) {
        _updateUserData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
  }

  Future<void> _updateUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final styleProvider = Provider.of<StyleProvider>(context, listen: false);
    await authService.updateUserData();
    int retry = 0;
    while (balanceProvider.ignoreRemoteBalanceUpdate && retry < 5) {
      debugPrint('[MainScreen] sync/load заблокирован (ignoreRemoteBalanceUpdate=true), жду...');
      await Future.delayed(const Duration(seconds: 1));
      retry++;
    }
    if (!balanceProvider.ignoreRemoteBalanceUpdate) {
      debugPrint('[MainScreen] _updateUserData: до syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
      await balanceProvider.syncLocalOrLoadRemoteBalance();
      debugPrint('[MainScreen] _updateUserData: после syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
    } else {
      debugPrint('[MainScreen] sync/load так и не разблокирован, пропускаю syncLocalOrLoadRemoteBalance');
    }
    await styleProvider.updateStylesForUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _videoController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _animationController.forward(from: 0.0);
  }

  // Добавляем метод для обновления системного UI
  void _updateSystemUI() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: themeProvider.isDarkMode 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).colorScheme.background,
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final balanceProvider = Provider.of<BalanceProvider>(context);
    debugPrint('[MainScreen] build: текущий баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
    
    return Stack(
      children: [
        AppScaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          bottomNavigationBar: ValueListenableBuilder<bool>(
            valueListenable: PlayScreen.isFreeSpinNotifier,
            builder: (context, isFreeSpin, child) {
              return CustomBottomNav(
                selectedIndex: _selectedIndex,
                onTap: (index) {
                  if (!languageProvider.showVideo && !isFreeSpin) {
                    _onItemTapped(index);
                  }
                },
              );
            },
          ),
        ),

        // Оверлей для блокировки навигации во время видео
        if (languageProvider.showVideo)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 100, // Высота навигационной панели
                color: Colors.transparent,
                child: IgnorePointer(
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 