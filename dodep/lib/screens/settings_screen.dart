import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import 'dart:ui';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late VideoPlayerController _videoController;
  late AnimationController _textAnimationController;
  late Animation<double> _textScaleAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = CurvedAnimation(
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  // Добавляем обработчик кнопки назад
  Future<bool> _onWillPop() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (languageProvider.showVideo) {
      languageProvider.hideVideo();
      _videoController.pause();
      _videoController.seekTo(Duration.zero);
      return false;
    }
    return true;
  }

  void _handleLanguageToggle(bool value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.toggleLanguage();
  }

  // Функция для открытия URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authService = Provider.of<AuthService>(context);

    // Добавляем эффект для воспроизведения видео при его появлении
    if (languageProvider.showVideo && _videoController.value.isInitialized && !_videoController.value.isPlaying) {
      _videoController.play();
      _textAnimationController.forward(from: 0.0);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Stack(
          children: [
            // Основное содержимое экрана настроек
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Настройки',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Переключатель темы
                      Card(
                        elevation: 2,
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          leading: Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Темная тема',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                               color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Переключатель языка
                      Card(
                        elevation: 2,
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            'Английский язык',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                               color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          trailing: Switch(
                            value: Provider.of<LanguageProvider>(context).isEnglish,
                            onChanged: _handleLanguageToggle,
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Кнопка выхода
                      Card(
                        elevation: 2,
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          title: Text(
                            'Выйти из аккаунта',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          onTap: () async {
                            await authService.logout();
                            if (mounted) {
                              Navigator.pushReplacementNamed(context, '/auth');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Затемнение фона при показе видео
            if (languageProvider.showVideo)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
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

            // Кнопка Автор внизу справа с анимацией
            Positioned(
              right: 16.0,
              bottom: 16.0,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _launchUrl('tg://resolve?domain=kagayakisan');
                  },
                  label: Text('Автор', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),),
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/author_avatar.png'),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 6.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 