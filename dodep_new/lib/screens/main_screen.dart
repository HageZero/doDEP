import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
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
      duration: const Duration(milliseconds: 1500),
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

    _updateUserData();
  }

  Future<void> _updateUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final styleProvider = Provider.of<StyleProvider>(context, listen: false);

    await authService.updateUserData();
    await balanceProvider.updateBalanceForUser();
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    // Добавляем эффект для воспроизведения видео при его появлении
    if (languageProvider.showVideo && _videoController.value.isInitialized && !_videoController.value.isPlaying) {
      _videoController.play();
      _textAnimationController.forward(from: 0.0);
    }
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
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
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              if (!languageProvider.showVideo) {
                _onItemTapped(index);
              }
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

        // Затемнение фона при показе видео
        if (languageProvider.showVideo)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

        // Текст поверх всего
        if (languageProvider.showMessage)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Transform.scale(
                    scale: _textScaleAnimation.value,
                    child: Center(
                      child: Text(
                        'чума suck my balls',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Theme.of(context).colorScheme.primary,
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Видео поверх всего
        if (languageProvider.showVideo && _videoController.value.isInitialized)
          Positioned.fill(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 