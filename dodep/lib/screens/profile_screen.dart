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
import '../widgets/app_scaffold.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/cache_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../providers/style_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _showSuccessAnimation = false;
  bool _isOffline = false;
  String? _localAvatarPath;
  bool? _hasInternet;
  int? _avatarCacheBuster;
  String? _lastNetworkAvatarPath;

  @override
  void initState() {
    super.initState();
    _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _hasInternet = result != ConnectivityResult.none;
      });
    });
    CacheService.getAvatarLocalPath().then((localPath) {
      if (localPath != null && File(localPath).existsSync()) {
        setState(() {
          _localAvatarPath = localPath;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
      Connectivity().checkConnectivity().then((result) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });
        if (!_isOffline) {
          _refreshUserData();
        }
      });
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

  Future<void> _cacheNetworkAvatar(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/profile_avatar.jpg';
        final localFile = File(localPath);
        await localFile.writeAsBytes(response.bodyBytes);
        await CacheService.saveAvatarLocalPath(localPath);
        if (mounted) {
          setState(() {
            _localAvatarPath = localPath;
          });
        }
      }
    } catch (e) {
      debugPrint('Ошибка при кэшировании аватара: $e');
    }
  }

  Future<void> _updateLocalAvatarPath() async {
    final localPath = await CacheService.getAvatarLocalPath();
    if (mounted) {
      setState(() {
        _localAvatarPath = (localPath != null && File(localPath).existsSync()) ? localPath : null;
      });
    }
  }

  Future<void> _afterAvatarChanged(String? avatarPath) async {
    if (avatarPath != null && avatarPath.startsWith('http')) {
      await _cacheNetworkAvatar(avatarPath);
    }
    await _updateLocalAvatarPath();
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
            Navigator.of(context).pop(); // Закрываем диалог подготовки
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
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                Navigator.of(context).pop(); // Закрываем диалог загрузки
                await authService.forceRefreshUserData();
                final newAvatarPath = authService.getCurrentUserSync()?.avatarPath;
                await _afterAvatarChanged(newAvatarPath);
                setState(() {
                  _showSuccessAnimation = true;
                  _avatarCacheBuster = DateTime.now().millisecondsSinceEpoch;
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
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      int retry = 0;
      while (balanceProvider.ignoreRemoteBalanceUpdate && retry < 5) {
        debugPrint('[ProfileScreen] sync/load заблокирован (ignoreRemoteBalanceUpdate=true), жду...');
        await Future.delayed(const Duration(seconds: 1));
        retry++;
      }
      if (!balanceProvider.ignoreRemoteBalanceUpdate) {
        debugPrint('[ProfileScreen] _refreshUserData: до syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
        await balanceProvider.syncLocalOrLoadRemoteBalance();
        debugPrint('[ProfileScreen] _refreshUserData: после syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
      } else {
        debugPrint('[ProfileScreen] sync/load так и не разблокирован, пропускаю syncLocalOrLoadRemoteBalance');
      }
      // Обновляем аватар
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении данных профиля: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.getCurrentUserSync();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final styleProvider = Provider.of<StyleProvider>(context);
    final selectedStyle = styleProvider.getStyleById(styleProvider.selectedStyleId);

    return AppScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              final avatarPath = authService.getCurrentUserSync()?.avatarPath;
                              if (_hasInternet == true && avatarPath != null && avatarPath.startsWith('http')) {
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: ClipOval(
                                    child: Image.network(
                                      avatarPath,
                                      key: ValueKey(avatarPath),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(child: CircularProgressIndicator());
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        if (_localAvatarPath != null) {
                                          return Image.file(
                                            File(_localAvatarPath!),
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          );
                                        }
                                        return Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onPrimaryContainer);
                                      },
                                    ),
                                  ),
                                );
                              } else if (_localAvatarPath != null) {
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: FileImage(File(_localAvatarPath!)),
                                );
                              } else {
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                );
                              }
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
                          'Изменить аватарку',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        onTap: _pickImage,
                      ),
                    ),
                    if (selectedStyle.id == 'minecraft')
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Center(
                          child: Image.asset(
                            'assets/images/nether.png',
                            width: 400,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
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