import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _avatarImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final avatarPath = await authService.getCurrentUserAvatar();
    if (avatarPath != null && mounted) {
      setState(() {
        _avatarImage = File(avatarPath);
      });
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      if (await Permission.photos.request().isGranted) {
        return true;
      }
      if (await Permission.mediaLibrary.request().isGranted) {
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Необходим доступ к галерее для выбора изображения'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() {
          _avatarImage = File(image.path);
        });
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.setCurrentUserAvatar(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе изображения: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.getCurrentUserSync();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Text(
                'Профиль',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Аватар и имя пользователя
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: _avatarImage != null
                          ? ClipOval(
                              child: Image.file(
                                _avatarImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return ClipOval(
                                    child: Image.asset(
                                      'assets/images/default_avatar.jpg',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/default_avatar.jpg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentUser?.username ?? 'Пользователь',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка редактирования профиля
              Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Редактировать профиль',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(height: 16),

              // Настройки
              Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.surface,
                child: ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Настройки',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
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
    );
  }
} 