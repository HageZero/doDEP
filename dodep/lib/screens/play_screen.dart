import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/slot_reel.dart'; // Импортируем виджет барабана
import '../widgets/daily_quests_dialog.dart';
import '../widgets/app_scaffold.dart';
import '../models/slot_symbol.dart';
import 'dart:math'; // Для генерации случайных чисел
import 'dart:async';
import 'package:collection/collection.dart'; // Для shuffle
import 'package:flutter/rendering.dart';
import 'dart:ui'; // Добавляем импорт для ImageFilter
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/quests_provider.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  // Перемещаем ValueNotifier сюда, чтобы был доступен как PlayScreen.isFreeSpinNotifier
  static final ValueNotifier<bool> isFreeSpinNotifier = ValueNotifier(false);

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  late List<SlotSymbol> _symbols;
  late List<SlotSymbol> _currentSymbols;
  late StyleProvider _styleProvider;

  final Random _random = Random();
  bool _isSpinning = false;
  late AnimationController _spinAnimationController;
  late List<Animation<double>> _reelAnimations;
  late AnimationController _winAnimationController;
  late List<Animation<double>> _winAnimations;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotationAnimationController;
  late Animation<double> _rotationAnimation;
  int _spinCost = 50;

  late List<List<SlotSymbol>> _reelSymbols = List.generate(3, (_) => []);

  bool _showFinal = false;
  static const int _reelLength = 20;
  static const int _centerIndex = _reelLength - 2; // центральная позиция для итогового символа
  String? _winMessage;
  bool _showWinMessage = false;
  bool _isBigWin = false;
  bool _showAddBalanceNotification = false;
  bool _isNotificationVisible = false;
  int _dodepCount = 0; // Счетчик использованных додепов
  DateTime? _lastDodepTime; // Время последнего додепа
  Timer? _dodepTimer; // Таймер для обновления UI
  String _dodepTimerText = ''; // Текст таймера

  // Вероятности выпадения комбинаций (сумма должна быть ~1.0)
  final double _prob3Same = 0.05; // 5%
  final double _prob2Same = 0.25; // 25%
  final double _prob3Diff = 0.70; // 70%

  late final BalanceProvider _balanceProvider;
  static const String _lastDodepTimeKey = 'last_dodep_time';
  static const String _dodepCountKey = 'dodep_count';

  int _currentBet = 50; // Добавляем поле для текущей ставки

  late AudioPlayer _audioPlayer;
  bool _showSadHorse = false;

  int _winAmount = 0; // Добавляем поле для суммы выигрыша
  bool _isWin = false; // Добавляем поле для статуса выигрыша

  int _freeSpins = 0; // Количество бесплатных прокруток
  bool _isFreeSpin = false; // Флаг для отслеживания бесплатных прокруток
  Timer? _autoSpinTimer; // Таймер для автоматических прокруток

  bool get isFreeSpin => _isFreeSpin;

  bool _isOffline = false;

  bool _wasAddBalanceNotificationVisible = false;
  AudioPlayer? _depaAudioPlayer;

  // Для подсчёта подряд проигрышей и подряд "lucky"
  int _loseStreak = 0;
  int _luckyStreak = 0;

  // Добавить счетчик для подряд проигрышей
  int _loseQuestProgress = 0;

  bool _isBonusFreeSpins = false;

  // --- Lucky Block ---
  DateTime? _lastLuckyBlockTime;
  bool _showLuckyBlock = false;
  Timer? _luckyBlockTimer;

  static const String _lastLuckyBlockTimeKey = 'last_lucky_block_time';

  @override
  void initState() {
    super.initState();
    _balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    
    // Инициализируем контроллеры анимации
    _spinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _winAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Инициализируем анимации
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.easeInOut,
    ));

    _reelAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: (_reelLength - 3).toDouble(),
      ).animate(
        CurvedAnimation(
          parent: _spinAnimationController,
          curve: Interval(
            index * 0.2,
            (index + 1) * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _winAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: -10.0,
      ).animate(
        CurvedAnimation(
          parent: _winAnimationController,
          curve: Curves.elasticOut,
        ),
      );
    });

    // Добавляем слушатели статуса анимации
    _spinAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isSpinning = false;
            _showFinal = true;
          });
          _checkWin();
        }
      }
    });

    _winAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _winAnimationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isBigWin = false;
            _checkBalanceForNotification();
          });
        }
      }
    });

    // Инициализируем остальные компоненты
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSymbols();
      _balanceProvider.addListener(_checkBalanceForNotification);
      _updateSystemUI();
    });

    _loadDodepState();
    _startDodepTimer();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(10.0);
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _freeSpins = 0;
    _isFreeSpin = false;

    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });

    _loadLuckyBlockTime();
    _startLuckyBlockTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _styleProvider = Provider.of<StyleProvider>(context, listen: false);
    _styleProvider.addListener(_onStyleChanged);
  }

  void _onStyleChanged() {
    if (!mounted) return;
    
    // Используем Future.microtask для отложенного обновления
    Future.microtask(() {
      if (!mounted) return;
      _updateSymbols();
    });
  }

  void _updateSymbols() {
    if (!mounted) return;
    
    final selectedStyle = _styleProvider.selectedStyleId;

    List<SlotSymbol> newSymbols;
    switch (selectedStyle) {
      case 'minecraft':
        newSymbols = SlotSymbols.minecraft;
        break;
      case 'yamete':
        newSymbols = SlotSymbols.yamete;
        break;
      case 'hellokitty':
        newSymbols = SlotSymbols.hellokitty;
        break;
      case 'dresnya':
        newSymbols = SlotSymbols.dresnya;
        break;
      case 'doka3':
        newSymbols = SlotSymbols.doka3;
        break;
      case 'lego':
        newSymbols = SlotSymbols.lego;
        break;
      case 'tokyopuk':
        newSymbols = SlotSymbols.tokyopuk;
        break;
      case 'fantasy_gacha':
        newSymbols = SlotSymbols.fantasyGacha;
        break;
      default:
        newSymbols = SlotSymbols.classic;
    }

    if (mounted) {
      setState(() {
        _symbols = newSymbols;
        _currentSymbols = [
          _symbols[0],
          _symbols[0],
          _symbols[0],
        ];
        _reelSymbols = List.generate(3, (_) => 
          List.generate(_reelLength, (_) => _symbols[_random.nextInt(_symbols.length)]));
      });
    }
  }

  void _updateSystemUI() {
    if (!mounted) return;
    
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

  Future<void> _loadDodepState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDodepTimeStr = prefs.getString(_lastDodepTimeKey);
    final dodepCount = prefs.getInt(_dodepCountKey) ?? 0;

    if (lastDodepTimeStr != null) {
      final lastDodepTime = DateTime.parse(lastDodepTimeStr);
      final now = DateTime.now();
      final difference = now.difference(lastDodepTime);

      if (difference.inMinutes >= 3) {
        // Если прошло 3 минуты, сбрасываем счетчик
        await prefs.setInt(_dodepCountKey, 0);
        setState(() {
          _dodepCount = 0;
          _lastDodepTime = null;
          _dodepTimerText = '';
        });
      } else {
        setState(() {
          _dodepCount = dodepCount;
          _lastDodepTime = lastDodepTime;
        });
        _startDodepTimer();
      }
    }
  }

  Future<void> _saveDodepState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastDodepTime != null) {
      await prefs.setString(_lastDodepTimeKey, _lastDodepTime!.toIso8601String());
      await prefs.setInt(_dodepCountKey, _dodepCount);
    } else {
      await prefs.remove(_lastDodepTimeKey);
      await prefs.setInt(_dodepCountKey, 0);
    }
  }

  void _startDodepTimer() {
    _dodepTimer?.cancel();
    _dodepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_lastDodepTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastDodepTime!);
        final remainingTime = const Duration(minutes: 3) - difference;
        
        if (remainingTime.isNegative) {
          if (mounted) {
            setState(() {
              _dodepCount = (_dodepCount - 1).clamp(0, 3);
              _lastDodepTime = DateTime.now();
              _saveDodepState();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              final minutes = remainingTime.inMinutes;
              final seconds = remainingTime.inSeconds % 60;
              _dodepTimerText = 'Додеп: ${3 - _dodepCount}/3 (${minutes}:${seconds.toString().padLeft(2, '0')})';
            });
          }
        }
      }
    });
  }

  void _checkBalanceForNotification() {
     if (_balanceProvider.balance < 50 && !_isSpinning && !_showAddBalanceNotification && !_winAnimationController.isAnimating) {
       Future.delayed(const Duration(seconds: 3), () {
         if (mounted && _balanceProvider.balance < 50) {
       setState(() {
         _showAddBalanceNotification = true;
             _isNotificationVisible = true;
           });
         }
       });
     } else if ((_balanceProvider.balance >= 50 || _isSpinning || _winAnimationController.isAnimating) && _showAddBalanceNotification) {
        setState(() {
          _isNotificationVisible = false;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
        setState(() {
          _showAddBalanceNotification = false;
            });
          }
        });
     }
  }

  bool _canDodep() {
    if (_lastDodepTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastDodepTime!);
    return _dodepCount < 3 || difference.inMinutes >= 3;
  }

  void _showSadHorseAnimation() async {
    if (!mounted) return;
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 2500),
          curve: Curves.easeInOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              color: Colors.black.withOpacity(0.5 * value),
              child: Center(
                child: Transform.scale(
                  scale: 0.3 + (0.7 * value),
                  child: Image.asset(
                    'assets/images/sadhorse.gif',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
    
    try {
      await _audioPlayer.stop(); // Останавливаем предыдущее воспроизведение
      await _audioPlayer.setVolume(2.0);
      await _audioPlayer.play(AssetSource('sounds/sfx.m4a'), volume: 10.0);
    } catch (e) {
      print('Ошибка воспроизведения звука: $e');
    }
    
    await Future.delayed(const Duration(seconds: 4));
    
    overlayEntry.remove();
  }

  void _handleDodep() {
    if (!_canDodep()) {
      _showSadHorseAnimation();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Додеп будет доступен через ${_dodepTimerText.split('(')[1].split(')')[0]}'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isNotificationVisible = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _balanceProvider.addBalance(300);
        setState(() {
          _showAddBalanceNotification = false;
          _dodepCount++;
          if (_lastDodepTime == null) {
            _lastDodepTime = DateTime.now();
          }
        });
        _saveDodepState();
      }
    });
  }

  void _startFreeSpins() {
    setState(() {
      _freeSpins = 10;
      _isFreeSpin = true;
      _isBonusFreeSpins = false;
      PlayScreen.isFreeSpinNotifier.value = true;
    });
    _startAutoSpin();
  }

  void _startBonusFreeSpins() {
    setState(() {
      _currentBet = 50;
      _freeSpins = 10;
      _isFreeSpin = true;
      _isBonusFreeSpins = true;
      PlayScreen.isFreeSpinNotifier.value = true;
    });
    _startAutoSpin();
  }

  void _startAutoSpin() {
    if (_freeSpins > 0 && !_isSpinning) {
      _autoSpinTimer?.cancel();
      _autoSpinTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _spinReels();
        }
      });
    } else if (_freeSpins == 0) {
      setState(() {
        _isFreeSpin = false;
        PlayScreen.isFreeSpinNotifier.value = false;
      });
      _autoSpinTimer?.cancel();
    }
  }

  void _checkWin() async {
    final questsProvider = Provider.of<QuestsProvider>(context, listen: false);
    if (_currentSymbols[0].name == _currentSymbols[1].name && 
        _currentSymbols[1].name == _currentSymbols[2].name) {
      
      // Проверяем, является ли комбинация тремя бонусами
      if (_currentSymbols[0].name == 'bonus') {
        setState(() {
          _freeSpins += _isFreeSpin ? 2 : 10;
          _winMessage = _isFreeSpin ? 'Бонус! +2 бесплатные прокрутки' : 'Бонус! 10 бесплатных прокруток';
          _showWinMessage = true;
        });
        
        if (!_isFreeSpin) {
          _startFreeSpins();
        }
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showWinMessage = false;
            });
          }
        });

        if (_isFreeSpin) {
          setState(() {
            _freeSpins--;
          });
          _startAutoSpin();
        }

        // bigwin
        if (_winAmount > 500) {
          questsProvider.updateQuestProgress('bigwin', 1);
        }

        // Сбросить прогресс задания lose
        _loseQuestProgress = 0;
        questsProvider.updateQuestProgress('lose', 0, absolute: true);
        _luckyStreak = 0;

        if (_isFreeSpin && _isBonusFreeSpins && _winAmount > 0) {
          setState(() {
            _currentBet += 50;
          });
        }

        return;
      }

      // Обычный джекпот
      int winMultiplier = _currentSymbols[0].specialMultiplier ?? 2;
      int winAmount = _currentBet * winMultiplier;
      
      setState(() {
        _winAmount = winAmount;
        _isWin = true;
        _winMessage = 'Джекпот! x$winMultiplier';
        _showWinMessage = true;
        _isBigWin = true;
      });
      
      _winAnimationController.forward(from: 0.0);
      _rotationAnimationController.repeat(reverse: true);
      
      // Обновляем баланс локально
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      debugPrint('[PlayScreen] _checkWin: addBalance($winAmount)');
      balanceProvider.addBalance(winAmount);

      // Обновляем прогресс заданий
      questsProvider.updateQuestProgress('coins', winAmount);
      questsProvider.updateQuestProgress('jackpots', 1);
      
      // Пытаемся обновить максимальный выигрыш в Firebase только если есть интернет
      if (!_isOffline) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          authService.updateMaxWin(winAmount).then((_) {
            debugPrint('Максимальный выигрыш обновлен: $winAmount');
          }).catchError((e) {
            debugPrint('Ошибка при обновлении максимального выигрыша: $e');
          });
        } catch (e) {
          debugPrint('Не удалось обновить максимальный выигрыш: $e');
        }
      }
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWinMessage = false;
            _rotationAnimationController.stop();
          });
        }
      });

      // bigwin
      if (_winAmount > 500) {
        questsProvider.updateQuestProgress('bigwin', 1);
      }

      // Сбросить прогресс задания lose
      _loseQuestProgress = 0;
      questsProvider.updateQuestProgress('lose', 0, absolute: true);

      if (_isFreeSpin && _isBonusFreeSpins && _winAmount > 0) {
        setState(() {
          _currentBet += 50;
        });
      }
    } else if (_currentSymbols[0].name == _currentSymbols[1].name || 
               _currentSymbols[1].name == _currentSymbols[2].name || 
               _currentSymbols[0].name == _currentSymbols[2].name) {
      // Два одинаковых символа
      int winAmount = _currentBet;
      setState(() {
        _winAmount = winAmount;
        _isWin = true;
        _winMessage = 'Выигрыш! x1';
        _showWinMessage = true;
        _isBigWin = false;
      });
      
      // Обновляем баланс локально
      final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
      debugPrint('[PlayScreen] _checkWin: addBalance($winAmount)');
      balanceProvider.addBalance(winAmount);

      // Обновляем прогресс заданий
      questsProvider.updateQuestProgress('coins', winAmount);
      
      // Пытаемся обновить максимальный выигрыш в Firebase только если есть интернет
      if (!_isOffline) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          authService.updateMaxWin(winAmount).then((_) {
            debugPrint('Максимальный выигрыш обновлен: $winAmount');
          }).catchError((e) {
            debugPrint('Ошибка при обновлении максимального выигрыша: $e');
          });
        } catch (e) {
          debugPrint('Не удалось обновить максимальный выигрыш: $e');
        }
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showWinMessage = false;
          });
        }
      });

      _luckyStreak++;
      if (_luckyStreak >= 2) {
        questsProvider.updateQuestProgress('lucky', 1);
        _luckyStreak = 0;
      }

      // Сбросить прогресс задания lose
      _loseQuestProgress = 0;
      questsProvider.updateQuestProgress('lose', 0, absolute: true);

      if (_isFreeSpin && _isBonusFreeSpins && _winAmount > 0) {
        setState(() {
          _currentBet += 50;
        });
      }
    } else {
      setState(() {
        _isWin = false;
        _winMessage = '';
        _showWinMessage = false;
        _isBigWin = false;
      });

      _loseStreak++;
      if (_loseStreak >= 5) {
        questsProvider.updateQuestProgress('lose', 1);
        _loseStreak = 0;
      }

      // Сбросить прогресс задания lose
      _loseQuestProgress++;
      questsProvider.updateQuestProgress('lose', _loseQuestProgress, absolute: true);
    }

    // Если это была бесплатная прокрутка (и не бонусная комбинация), уменьшаем счетчик и запускаем следующую
    if (_isFreeSpin && !(_currentSymbols[0].name == 'bonus' && 
        _currentSymbols[1].name == 'bonus' && 
        _currentSymbols[2].name == 'bonus')) {
      setState(() {
        _freeSpins--;
      });
      _startAutoSpin();
    }

    // После окончания бесплатных прокруток:
    if (_isFreeSpin && _freeSpins == 0 && _isBonusFreeSpins) {
      setState(() {
        _isBonusFreeSpins = false;
        _currentBet = 50;
      });
    }
  }

  void _spinReels() {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final questsProvider = Provider.of<QuestsProvider>(context, listen: false);
    debugPrint('[PlayScreen] _spinReels: текущий баланс: [33m${balanceProvider.balance}[0m');
    if (_isSpinning) return;
    if (!_isFreeSpin && balanceProvider.balance < _currentBet) {
      _checkBalanceForNotification();
      return;
    }

    // Обновляем прогресс задания на прокрутки
    questsProvider.updateQuestProgress('spins', 1);

    // Обновляем прогресс задания на ставку
    if (!_isFreeSpin) {
      questsProvider.updateQuestProgress('bet', _currentBet);
    }

    // Проверяем и инициализируем символы, если они еще не инициализированы
    if (_symbols.isEmpty) {
      _updateSymbols();
      if (_symbols.isEmpty) {
        // Если все еще пусто, используем классические символы
        _symbols = SlotSymbols.classic;
      }
    }

    // Проверяем, что у нас есть все необходимые символы
    if (_symbols.isEmpty || _symbols.length < 3) {
      debugPrint('Ошибка: недостаточно символов для игры');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка инициализации игры'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // --- 1. Сначала запускаем анимацию и обновляем UI ---
    setState(() {
      _isSpinning = true;
      _showFinal = false;
      _winMessage = null;
      _showWinMessage = false;
      _isBigWin = false;
      _showAddBalanceNotification = false;
    });

    // Генерируем случайные символы
    final randomValue = _random.nextDouble();
    List<SlotSymbol> nextSymbols = [];

    if (randomValue < 0.2) {
      // 20% шанс на три одинаковых символа
      SlotSymbol randomSymbol = _symbols[_random.nextInt(_symbols.length)];
      nextSymbols = [randomSymbol, randomSymbol, randomSymbol];
    } else if (randomValue < 0.35) {
      // 35% шанс на два одинаковых символа
      SlotSymbol symbol1 = _symbols[_random.nextInt(_symbols.length)];
      SlotSymbol symbol2;
      do {
        symbol2 = _symbols[_random.nextInt(_symbols.length)];
      } while (symbol2.name == symbol1.name);
      nextSymbols = [symbol1, symbol1, symbol2];
      nextSymbols.shuffle(_random);
    } else {
      // 45% шанс на три разных символа
      List<SlotSymbol> tempSymbols = List.from(_symbols);
      tempSymbols.shuffle(_random);
      nextSymbols = tempSymbols.sublist(0, min(3, tempSymbols.length));
    }

    // Сохраняем финальные символы
    final finalSymbols = List<SlotSymbol>.from(nextSymbols);
    _currentSymbols = finalSymbols;

    // Обновляем символы для каждого барабана
    for (int i = 0; i < 3; i++) {
      List<SlotSymbol> temp = List.generate(_reelLength, (_) => _symbols[_random.nextInt(_symbols.length)]);
      temp[_centerIndex] = finalSymbols[i];
      _reelSymbols[i] = temp;
    }

    // Запускаем анимацию
    if (mounted) {
      // Создаем новые анимации для каждого барабана
      _reelAnimations = List.generate(3, (index) {
        return Tween<double>(
          begin: 0.0,
          end: (_reelLength - 3).toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _spinAnimationController,
            curve: Interval(
              index * 0.2,
              (index + 1) * 0.2,
              curve: Curves.easeInOut,
            ),
          ),
        );
      });

      // Сбрасываем и запускаем анимацию
      _spinAnimationController.reset();
      _spinAnimationController.forward();
    }

    // --- 2. Асинхронные операции с балансом и интернетом ---
    Future(() async {
      try {
        if (!_isFreeSpin) {
          debugPrint('[PlayScreen] _spinReels: subtractBalance($_currentBet)');
          balanceProvider.subtractBalance(_currentBet);
        }
      } catch (e) {
        debugPrint('Ошибка при уменьшении баланса: $e');
      }
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.incrementSpinsCount();
        }
      } catch (e) {
        debugPrint('Не удалось обновить счетчик прокруток: $e');
      }
    });
  }

  void _showDepositDialog() {
    // Блокируем диалог во время бесплатных прокруток
    if (_isFreeSpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нельзя изменить ставку во время бесплатных прокруток'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Управление ставкой',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Текущая ставка: $_currentBet',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentBet = 50;
                        });
                        this.setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                      child: const Text(
                        'Сбросить ставку',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildBetButton(1000, setState),
                        _buildBetButton(500, setState),
                        _buildBetButton(300, setState),
                        _buildBetButton(100, setState),
                        _buildBetButton(50, setState),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildBetButton(-50, setState),
                        _buildBetButton(-100, setState),
                        _buildBetButton(-300, setState),
                        _buildBetButton(-500, setState),
                        _buildBetButton(-1000, setState),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBetButton(int amount, StateSetter setDialogState) {
    final isPositive = amount > 0;
    final color = isPositive 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.error;
    
    return ElevatedButton(
      onPressed: () {
        setDialogState(() {
          _currentBet = (_currentBet + amount).clamp(50, double.infinity).toInt();
        });
        setState(() {}); // Обновляем состояние основного виджета
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
      ),
      child: Text(
        '${amount > 0 ? '+' : ''}$amount',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildAddBalanceNotification(BuildContext context) {
    // Звук при первом появлении уведомления
    if (_isNotificationVisible && !_wasAddBalanceNotificationVisible && _dodepCount == 0) {
      _depaAudioPlayer?.stop();
      _depaAudioPlayer = AudioPlayer();
      _depaAudioPlayer!.play(AssetSource('sounds/depai.mp3'));
    } else if (!_isNotificationVisible && _wasAddBalanceNotificationVisible) {
      _depaAudioPlayer?.stop();
    }
    _wasAddBalanceNotificationVisible = _isNotificationVisible;

    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isNotificationVisible ? 1.0 : 0.0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: _isNotificationVisible ? 1.0 : 0.8,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  offset: _isNotificationVisible ? Offset.zero : const Offset(0, 0.1),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_dodepCount == 0) ...[
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2000),
                            curve: Curves.easeOutBack,
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value.clamp(0.0, 1.0),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: Image.asset(
                                    'assets/images/dodep.jpg',
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'додепался ты',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'и что ты теперь будешь делать?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        if (!_canDodep()) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Додеп будет доступен через ${_dodepTimerText.split('(')[1].split(')')[0]}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (!_canDodep()) {
                              _showSadHorseAnimation();
                            } else {
                              _handleDodep();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            )
                          ),
                          child: Text(
                            'ДОДЕП',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReel(int index) {
    final isMinecraft = _styleProvider.selectedStyleId == 'minecraft';
    if (_showFinal) {
      return AnimatedBuilder(
        animation: _isBigWin ? _pulseAnimation : _winAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _isBigWin ? _pulseAnimation.value : 1.0,
            child: Transform.rotate(
              angle: _isBigWin ? _rotationAnimation.value : 0.0,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isBigWin 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Theme.of(context).colorScheme.primary,
                    width: _isBigWin ? 3.0 : 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: _isBigWin
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: _isBigWin ? 12 : 8,
                      spreadRadius: _isBigWin ? 4 : 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Stack(
                    children: [
                      if (isMinecraft)
                        Image.asset(
                          'assets/images/minecraftslot.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _isBigWin
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                              _isBigWin
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: _currentSymbols[index].imagePath.isNotEmpty
                              ? Image.asset(_currentSymbols[index].imagePath, height: 60, width: 60, fit: BoxFit.contain)
                              : Text(_currentSymbols[index].name, style: TextStyle(fontSize: 40)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  if (isMinecraft)
                    Image.asset(
                      'assets/images/minecraftslot.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  AnimatedBuilder(
                    animation: _spinAnimationController,
                    builder: (context, child) {
                      double value = _reelAnimations[index].value;
                      double offset = value;
                      int firstIndex = offset.floor();
                      double dy = -(offset - firstIndex) * 80;
                      List<Widget> stackChildren = [];
                      for (int i = 0; i < 3; i++) {
                        int symbolIndex = firstIndex + i;
                        if (symbolIndex < _reelSymbols[index].length) {
                          stackChildren.add(Positioned(
                            top: (i * 80.0) + dy - 80,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              alignment: Alignment.center,
                              child: _reelSymbols[index][symbolIndex].imagePath.isNotEmpty
                                  ? Image.asset(_reelSymbols[index][symbolIndex].imagePath, height: 60, width: 60, fit: BoxFit.contain)
                                  : Text(_reelSymbols[index][symbolIndex].name, style: TextStyle(fontSize: 40)),
                            ),
                          ));
                        }
                      }
                      return Stack(children: stackChildren);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_styleProvider.selectedStyleId == 'yamete')
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: Color(0xFF404040),
                              width: 2.0,
                            ),
                          ),
                          child: Text(
                            'Казик',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Builder(
                          builder: (context) {
                            // Настраиваемые параметры:
                            const double lanternHeight = 170; // размер
                            const double lanternTopOffset = -4; // вверх/вниз (отрицательное - ближе к тексту)
                            const Alignment lanternAlignment = Alignment.center; // left, center, right
                            return Container(
                              alignment: lanternAlignment,
                              child: Transform.translate(
                                offset: Offset(0, lanternTopOffset),
                                child: IgnorePointer(
                                  child: Image.asset(
                                    'assets/images/lantern.png',
                                    height: lanternHeight,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  else
                    Text(
                      'Казик',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Consumer<BalanceProvider>(
                          builder: (context, balanceProvider, _) =>
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/emerald.png',
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${balanceProvider.balance}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => DailyQuestsDialog(onBonus: _startBonusFreeSpins),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/dailyquests.png',
                                width: 65,
                                height: 65,
                              ),
                            ),
                            Consumer<QuestsProvider>(
                              builder: (context, questsProvider, _) {
                                if (questsProvider.hasCompletedQuests) {
                                  return Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.surface,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_showLuckyBlock)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: GestureDetector(
                            onTap: _onLuckyBlockTap,
                            child: Image.asset(
                              _styleProvider.selectedStyleId == 'fantasy_gacha'
                                  ? 'assets/images/chest.png'
                                  : 'assets/images/luckyblock.png',
                              width: 70,
                              height: 70,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showWinMessage)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _showWinMessage ? 1.0 : 0.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                _winMessage ?? '',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20.0),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            'Ставка: $_currentBet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildReel(index),
                            )),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: (_isSpinning || _winAnimationController.isAnimating || _isFreeSpin) 
                              ? null 
                              : _spinReels,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            _isSpinning 
                                ? 'Крутится...' 
                                : _isFreeSpin 
                                    ? 'Бесплатные прокрутки' 
                                    : 'Крутить! (${_currentBet})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: (_isFreeSpin || _balanceProvider.balance <= 0) 
                              ? null 
                              : _showDepositDialog,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                            backgroundColor: (_isFreeSpin || _balanceProvider.balance <= 0)
                                ? Theme.of(context).colorScheme.surfaceVariant
                                : Theme.of(context).colorScheme.primaryContainer,
                          ),
                          child: Text(
                            'Депнуть',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: (_isFreeSpin || _balanceProvider.balance <= 0)
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (_showAddBalanceNotification)
                    _buildAddBalanceNotification(context),
                  if (_showSadHorse)
                    _buildSadHorseAnimation(),
                  if (_dodepTimerText.isNotEmpty && _dodepCount > 0)
                    Positioned(
                      top: 0,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          _dodepTimerText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_isFreeSpin)
                    Positioned(
                      top: (_dodepTimerText.isNotEmpty && _dodepCount > 0) ? 40 : 0,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          'Бесплатные прокрутки: $_freeSpins',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSadHorseAnimation() {
    return Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 2500),
        curve: Curves.easeInOut,
        tween: Tween(begin: 0.0, end: _showSadHorse ? 1.0 : 0.0),
        builder: (context, value, child) {
          return Container(
            color: Colors.black.withOpacity(0.5 * value),
            child: Center(
              child: Transform.scale(
                scale: 0.3 + (0.7 * value),
                child: Image.asset(
                  'assets/images/sadhorse.gif',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startLuckyBlockTimer() {
    _luckyBlockTimer?.cancel();
    _luckyBlockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _showLuckyBlock = _canShowLuckyBlock();
      });
    });
  }

  bool _canShowLuckyBlock() {
    if (_lastLuckyBlockTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastLuckyBlockTime!).inMinutes >= 10;
  }

  void _onLuckyBlockTap() {
    setState(() {
      _lastLuckyBlockTime = DateTime.now();
      _showLuckyBlock = false;
    });
    _saveLuckyBlockTime();
    // Рандомная награда
    final rewards = [
      ...List.filled(20, 50),
      ...List.filled(15, 100),
      ...List.filled(15, 150),
      ...List.filled(10, 300),
      ...List.filled(10, 500),
      ...List.filled(3, 1000),
      ...List.filled(3, 'bonus'),
    ];
    rewards.shuffle();
    final reward = rewards.first;
    if (reward == 'bonus') {
      _startBonusFreeSpins();
      _showRewardMessage('БОНУСКА', color: Colors.purpleAccent);
    } else {
      Provider.of<BalanceProvider>(context, listen: false).addBalance(reward as int);
      _showRewardMessage('+$reward к балансу!', color: Colors.green);
    }
  }

  void _showRewardMessage(String text, {Color? color}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final anim = (value < 0.8 ? value : (2 - value)).clamp(0.0, 1.0);
              return Opacity(
                opacity: anim,
                child: Transform.scale(
                  scale: anim,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: (color ?? Colors.amber).withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (color ?? Colors.amber).withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1800), () {
      entry.remove();
    });
  }

  Future<void> _loadLuckyBlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeStr = prefs.getString(_lastLuckyBlockTimeKey);
    if (lastTimeStr != null) {
      setState(() {
        _lastLuckyBlockTime = DateTime.tryParse(lastTimeStr);
      });
    }
  }

  Future<void> _saveLuckyBlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastLuckyBlockTime != null) {
      await prefs.setString(_lastLuckyBlockTimeKey, _lastLuckyBlockTime!.toIso8601String());
    }
  }

  @override
  void dispose() {
    _dodepTimer?.cancel();
    _spinAnimationController.stop();
    _spinAnimationController.dispose();
    _winAnimationController.stop();
    _winAnimationController.dispose();
    _pulseAnimationController.stop();
    _pulseAnimationController.dispose();
    _rotationAnimationController.stop();
    _rotationAnimationController.dispose();
    _balanceProvider.removeListener(_checkBalanceForNotification);
    _saveDodepState();
    _audioPlayer.dispose();
    _autoSpinTimer?.cancel();
    
    // Отписываемся от StyleProvider перед удалением виджета
    _styleProvider.removeListener(_onStyleChanged);
    
    _depaAudioPlayer?.stop();
    _depaAudioPlayer?.dispose();
    
    _luckyBlockTimer?.cancel();
    
    _saveLuckyBlockTime();
    
    super.dispose();
  }
} 