import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../models/app_user.dart';
import 'settings_screen.dart';
import '../providers/balance_provider.dart';
import '../widgets/success_animation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _avatarImage;
  final _picker = ImagePicker();
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    // Добавляем слушатель изменения темы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
      // Принудительно обновляем данные при входе в профиль
      _refreshUserData();
    });
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

  Future<void> _loadAvatar() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.getCurrentUserSync();
      
      if (currentUser?.avatarPath != null && mounted) {
          setState(() {
          _avatarImage = null; // Сбрасываем локальный файл
          });
        debugPrint('Загружен путь к аватару из Firebase: ${currentUser!.avatarPath}');
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке аватара: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке аватара: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        try {
          // Показываем диалог загрузки
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Подготовка изображения...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          );

          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            compressQuality: 85,
            maxWidth: 1024,
            maxHeight: 1024,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Кадрирование',
                toolbarColor: Theme.of(context).colorScheme.primary,
                toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
                hideBottomControls: true,
                showCropGrid: true,
                activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
                statusBarColor: Theme.of(context).colorScheme.background,
                backgroundColor: Theme.of(context).colorScheme.background,
              ),
              IOSUiSettings(
                title: 'Кадрирование',
                doneButtonTitle: 'Готово',
                cancelButtonTitle: 'Отмена',
                resetAspectRatioEnabled: false,
                aspectRatioLockEnabled: true,
                rotateButtonsHidden: true,
                resetButtonHidden: true,
                minimumAspectRatio: 1.0,
                aspectRatioPickerButtonHidden: true,
              ),
            ],
          );

          if (croppedFile != null && mounted) {
            // Обновляем текст в диалоге
            Navigator.of(context).pop();
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Загрузка аватара...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            );

            try {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.setCurrentUserAvatar(croppedFile.path);
              
              if (mounted) {
                Navigator.of(context).pop(); // Закрываем диалог загрузки
                setState(() {
                  _showSuccessAnimation = true;
                });
                _updateSystemUI();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Аватар успешно обновлен'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.of(context).pop(); // Закрываем диалог загрузки
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка при обновлении аватара: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              Navigator.of(context).pop(); // Закрываем диалог подготовки
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // Закрываем диалог в случае ошибки
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при обработке изображения: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
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

  // Добавляем метод для обновления данных
  Future<void> _refreshUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.forceRefreshUserData();
      
      // Обновляем баланс
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      await balanceProvider.updateBalanceForUser();
      
      // Обновляем аватар
      await _loadAvatar();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Добавляем слушатель изменения темы
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (themeProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
      });
    }

    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.getCurrentUserSync();
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и кнопка настроек в одной строке
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Профиль',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Аватар и имя пользователя
              Center(
                child: Column(
                  children: [
                        Consumer<AuthService>(
                          builder: (context, authService, _) {
                            final user = authService.getCurrentUserSync();
                            return CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: user?.avatarPath != null
                          ? ClipOval(
                                      child: Image.network(
                                        user!.avatarPath!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          );
                                        },
                                errorBuilder: (context, error, stackTrace) {
                                          debugPrint('Ошибка загрузки аватара: $error');
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
                            );
                          },
                    ),
                    const SizedBox(height: 16),
                    Consumer<AuthService>(
                      builder: (context, authService, _) {
                        final user = authService.getCurrentUserSync();
                        return Text(
                          user?.username ?? 'Загрузка...',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        );
                      },
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
                        'Изменить аватар',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: _pickImage,
                ),
              ),
            ],
          ),
        ),
          ),

          // Анимация успеха
          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: SuccessAnimation(
                size: 150,
                onComplete: () {
                  if (mounted) {
                    setState(() {
                      _showSuccessAnimation = false;
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
} 