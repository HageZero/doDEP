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
import 'package:cloud_firestore/cloud_firestore.dart';

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
        statusBarIconBrightness:
            themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).colorScheme.background,
        systemNavigationBarIconBrightness:
            themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
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
        _localAvatarPath = (localPath != null && File(localPath).existsSync())
            ? localPath
            : null;
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
              content:
                  Text('Необходим доступ к галерее для выбора изображения'),
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
                activeControlsWidgetColor:
                    Theme.of(context).colorScheme.primary,
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
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.setCurrentUserAvatar(croppedFile.path);
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                Navigator.of(context).pop(); // Закрываем диалог загрузки
                await authService.forceRefreshUserData();
                final newAvatarPath =
                    authService.getCurrentUserSync()?.avatarPath;
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
      final balanceProvider =
          Provider.of<BalanceProvider>(context, listen: false);
      int retry = 0;
      while (balanceProvider.ignoreRemoteBalanceUpdate && retry < 5) {
        debugPrint(
            '[ProfileScreen] sync/load заблокирован (ignoreRemoteBalanceUpdate=true), жду...');
        await Future.delayed(const Duration(seconds: 1));
        retry++;
      }
      if (!balanceProvider.ignoreRemoteBalanceUpdate) {
        debugPrint(
            '[ProfileScreen] _refreshUserData: до syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
        await balanceProvider.syncLocalOrLoadRemoteBalance();
        debugPrint(
            '[ProfileScreen] _refreshUserData: после syncLocalOrLoadRemoteBalance, баланс: \x1b[33m${balanceProvider.balance}\x1b[0m');
      } else {
        debugPrint(
            '[ProfileScreen] sync/load так и не разблокирован, пропускаю syncLocalOrLoadRemoteBalance');
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
    final selectedStyle =
        styleProvider.getStyleById(styleProvider.selectedStyleId);

    return AppScaffold(
      body: Stack(
        children: [
          SafeArea(
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
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
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
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Icon(
                                Icons.settings,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
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
                            final avatarPath =
                                authService.getCurrentUserSync()?.avatarPath;
                            if (_hasInternet == true &&
                                avatarPath != null &&
                                avatarPath.startsWith('http')) {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: ClipOval(
                                  child: Image.network(
                                    avatarPath,
                                    key: ValueKey(avatarPath),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                          child: CircularProgressIndicator());
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
                                      return Icon(Icons.person,
                                          size: 50,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer);
                                    },
                                  ),
                                ),
                              );
                            } else if (_localAvatarPath != null) {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                backgroundImage:
                                    FileImage(File(_localAvatarPath!)),
                              );
                            } else {
                              return CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(Icons.person,
                                    size: 50,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
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

                  const SizedBox(height: 24),
                  // Лидеры (только таблица скроллируется)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _LeaderboardWidget(),
                      if (selectedStyle.id == 'minecraft')
                        Positioned(
                          top: -80,
                          left: 0,
                          right: -230,
                          child: IgnorePointer(
                            child: Center(
                              child: Image.asset(
                                'assets/images/nether.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      if (selectedStyle.id == 'fantasy_gacha')
                        Positioned(
                          top: -80,
                          left: 0,
                          right: -230,
                          child: IgnorePointer(
                            child: Center(
                              child: Image.asset(
                                'assets/images/casstle.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      if (selectedStyle.id == 'yamete')
                        Positioned(
                          top: -30,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Image.asset(
                                'assets/images/tori2.png',
                                width: 100,
                                height: 400,
                              ),
                            ),
                          ),
                        ),
                      if (selectedStyle.id == 'doka3')
                        Positioned(
                          top: -100,
                          left: 0,
                          right: -230,
                          child: IgnorePointer(
                            child: Center(
                              child: Image.asset(
                                'assets/images/jugger.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
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

// --- Leaderboard Widget ---
class _LeaderboardWidget extends StatefulWidget {
  @override
  State<_LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<_LeaderboardWidget> {
  String _sortField = 'balance';
  final Map<String, String> _fieldNames = {
    'balance': 'Баланс',
    'spinsCount': 'Прокрутки',
    'maxWin': 'Макс. выигрыш',
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'топ деперы',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LeaderboardSortIcon(
                  icon: Icons.monetization_on,
                  label: 'Баланс',
                  selected: _sortField == 'balance',
                  onTap: () => setState(() => _sortField = 'balance'),
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                _LeaderboardSortIcon(
                  icon: Icons.refresh_rounded,
                  label: 'Прокрутки',
                  selected: _sortField == 'spinsCount',
                  onTap: () => setState(() => _sortField = 'spinsCount'),
                  color: iconColor,
                ),
                const SizedBox(width: 16),
                _LeaderboardSortIcon(
                  icon: Icons.emoji_events,
                  label: 'Макс. выигрыш',
                  selected: _sortField == 'maxWin',
                  onTap: () => setState(() => _sortField = 'maxWin'),
                  color: iconColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy(_sortField, descending: true)
                  .limit(10)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('Нет данных для отображения');
                }
                final docs = snapshot.data!.docs;
                return SizedBox(
                  height: 168,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: docs.length,
                    itemExtent: 56,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final avatarPath = data['avatarPath'] as String?;
                      final username = data['username'] ?? 'Без имени';
                      final statValue = data[_sortField] ?? 0;
                      Color placeColor;
                      switch (i) {
                        case 0:
                          placeColor = Colors.amber;
                          break;
                        case 1:
                          placeColor = Colors.grey[400]!;
                          break;
                        case 2:
                          placeColor = Colors.brown[300]!;
                          break;
                        default:
                          placeColor = Theme.of(context).colorScheme.primary;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Место в топе (фиксированная ширина)
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${i + 1}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: placeColor,
                                  height: 1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Аватарка и username строго по одной линии
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (avatarPath != null &&
                                      avatarPath.isNotEmpty)
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      backgroundImage: NetworkImage(avatarPath),
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      child: Icon(Icons.person,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer),
                                    ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$statValue',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Leaderboard Sort Icon Widget ---
class _LeaderboardSortIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _LeaderboardSortIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.15) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : Colors.grey[400]!,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: selected ? color : Colors.grey[600],
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
