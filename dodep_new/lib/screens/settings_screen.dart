import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    return Scaffold(
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
                    // Здесь может быть другое содержимое настроек
                  ],
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
                  _launchUrl('tg://resolve?domain=kagayakisan'); // Ссылка на Telegram
                },
                label: Text('Автор', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),), // Текст кнопки
                icon: CircleAvatar(
                  radius: 18, // Меньший радиус для аватара в кнопке
                  backgroundImage: AssetImage('assets/images/author_avatar.png'),
                ), // Изображение аватара
                backgroundColor: Theme.of(context).colorScheme.primary, // Цвет кнопки
                foregroundColor: Theme.of(context).colorScheme.onPrimary, // Цвет текста и иконки
                elevation: 6.0, // Тень кнопки
              ),
            ),
          ),
        ],
      ),
    );
  }
} 