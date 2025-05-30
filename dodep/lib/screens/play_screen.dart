import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import '../widgets/slot_reel.dart'; // Импортируем виджет барабана
import '../models/slot_symbol.dart';
import 'dart:math'; // Для генерации случайных чисел
import 'dart:async';
import 'package:collection/collection.dart'; // Для shuffle
import 'package:confetti/confetti.dart'; // Импортируем пакет confetti
import 'package:flutter/rendering.dart';
import 'dart:ui'; // Добавляем импорт для ImageFilter
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/auth_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  // Используем символы из модели SlotSymbols
  late List<SlotSymbol> _symbols;
  late List<SlotSymbol> _currentSymbols;

  final Random _random = Random();
  bool _isSpinning = false;
  late AnimationController _spinAnimationController;
  late List<Animation<double>> _reelAnimations;
  late AnimationController _winAnimationController;
  late List<Animation<double>> _winAnimations;
  late AnimationController _pulseAnimationController; // Новый контроллер для пульсации
  late Animation<double> _pulseAnimation; // Анимация пульсации
  late AnimationController _rotationAnimationController; // Контроллер для вращения
  late Animation<double> _rotationAnimation; // Анимация вращения
  late ConfettiController _confettiController;
  int _spinCost = 50; // Стоимость одного вращения

  // Списки символов для анимации каждого барабана
  late List<List<SlotSymbol>> _reelSymbols;
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

  late BalanceProvider _balanceProvider;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _balanceProvider = Provider.of<BalanceProvider>(context);
    _updateSymbols();
  }

  @override
  void initState() {
    super.initState();
    _loadDodepState();
    _spinAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _winAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _winAnimationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {
             _isBigWin = false;
             _checkBalanceForNotification();
          });
        }
      });

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.easeInOut,
    ));

    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    _updateSymbols();

    _currentSymbols = [
      _symbols[0],
      _symbols[0],
      _symbols[0],
    ];

    _reelSymbols = List.generate(3, (_) => List.generate(_reelLength, (_) => _symbols[_random.nextInt(_symbols.length)]));

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

    _spinAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _showFinal = true;
        });
        _checkWin();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _balanceProvider.addListener(_checkBalanceForNotification);
    });

    _startDodepTimer();

    _audioPlayer = AudioPlayer();
    _audioPlayer.setVolume(10.0);
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _freeSpins = 0;
    _isFreeSpin = false;
  }

  void _updateSymbols() {
    final styleProvider = Provider.of<StyleProvider>(context, listen: false);
    final selectedStyle = styleProvider.selectedStyleId;

    setState(() {
      switch (selectedStyle) {
        case 'minecraft':
          _symbols = SlotSymbols.minecraft;
          break;
        case 'fantasy_gacha':
          _symbols = SlotSymbols.fantasyGacha;
          break;
        case 'dresnya':
          _symbols = SlotSymbols.dresnya;
          break;
        case 'tokyopuk':
          _symbols = SlotSymbols.tokyopuk;
          break;
        case 'lego':
          _symbols = SlotSymbols.lego;
          break;
        case 'doka3':
          _symbols = SlotSymbols.doka3;
          break;
        case 'yamete':
          _symbols = SlotSymbols.yamete;
          break;
        case 'classic':
        default:
          _symbols = SlotSymbols.classic;
          break;
      }
      debugPrint('Загружены символы для стиля: $selectedStyle');
    });
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
      });
      _autoSpinTimer?.cancel();
    }
  }

  void _checkWin() {
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
      _confettiController.play();
      
      // Обновляем баланс и максимальный выигрыш
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.updateMaxWin(winAmount).then((_) {
        debugPrint('Максимальный выигрыш обновлен: $winAmount');
      }).catchError((e) {
        debugPrint('Ошибка при обновлении максимального выигрыша: $e');
      });
      
      Provider.of<BalanceProvider>(context, listen: false).addBalance(winAmount);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWinMessage = false;
            _rotationAnimationController.stop();
          });
        }
      });
    } else if (_currentSymbols[0].name == _currentSymbols[1].name || 
               _currentSymbols[1].name == _currentSymbols[2].name || 
               _currentSymbols[0].name == _currentSymbols[2].name) {
      // Два одинаковых символа
      SlotSymbol matchingSymbol;
      if (_currentSymbols[0].name == _currentSymbols[1].name) {
        matchingSymbol = _currentSymbols[0];
      } else if (_currentSymbols[1].name == _currentSymbols[2].name) {
        matchingSymbol = _currentSymbols[1];
      } else {
        matchingSymbol = _currentSymbols[0];
      }
      
      int winAmount = _currentBet;
      setState(() {
        _winAmount = winAmount;
        _isWin = true;
        _winMessage = 'Выигрыш! x1';
        _showWinMessage = true;
        _isBigWin = false;
      });
      
      // Обновляем баланс и максимальный выигрыш
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.updateMaxWin(winAmount).then((_) {
        debugPrint('Максимальный выигрыш обновлен: $winAmount');
      }).catchError((e) {
        debugPrint('Ошибка при обновлении максимального выигрыша: $e');
      });
      
      Provider.of<BalanceProvider>(context, listen: false).addBalance(winAmount);
      
      // Скрываем сообщение о выигрыше через 2 секунды
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showWinMessage = false;
          });
        }
      });
    } else {
      setState(() {
        _isWin = false;
        _winMessage = '';
        _showWinMessage = false;
        _isBigWin = false;
      });
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
  }

  void _spinReels() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (_isSpinning) return;
    if (!_isFreeSpin && balanceProvider.balance < _currentBet) {
       _checkBalanceForNotification();
      return;
    }

    setState(() {
      _isSpinning = true;
      _showFinal = false;
      _winMessage = null;
      _showWinMessage = false;
      _isBigWin = false;
      _showAddBalanceNotification = false;
    });

    try {
      if (!_isFreeSpin) {
        await balanceProvider.subtractBalance(_currentBet);
      }

      // Увеличиваем счетчик прокруток в Firebase
      await authService.incrementSpinsCount();

      double randomValue = _random.nextDouble();
      List<SlotSymbol> nextSymbols = [];

      // Определяем специальные символы
      final sevenSymbol = _symbols.firstWhere((s) => s.name == 'seven');
      final emeraldSymbol = _symbols.firstWhere((s) => s.name == 'emerald');
      final rubinSymbol = _symbols.firstWhere((s) => s.name == 'rubin');
      final bonusSymbol = _symbols.firstWhere((s) => s.name == 'bonus');

      if (randomValue < 0.03) { // 3% шанс на три бонуса (было 2%)
        nextSymbols = [bonusSymbol, bonusSymbol, bonusSymbol];
      } else if (randomValue < 0.07) { // 4% шанс на три семерки (было 3%)
        nextSymbols = [sevenSymbol, sevenSymbol, sevenSymbol];
      } else if (randomValue < 0.12) { // 5% шанс на три изумруда (было 3%)
        nextSymbols = [emeraldSymbol, emeraldSymbol, emeraldSymbol];
      } else if (randomValue < 0.20) { // 8% шанс на три рубина (было 5%)
        nextSymbols = [rubinSymbol, rubinSymbol, rubinSymbol];
      } else if (randomValue < 0.40) { // 20% шанс на два одинаковых символа (было 15%)
        // Выбираем случайный символ
        SlotSymbol symbol1 = _symbols[_random.nextInt(_symbols.length)];
        // Выбираем другой случайный символ
        SlotSymbol symbol2;
        do {
          symbol2 = _symbols[_random.nextInt(_symbols.length)];
        } while (symbol2 == symbol1);

        // Создаем комбинацию с двумя одинаковыми символами
        nextSymbols = [symbol1, symbol1, symbol2];
        // Перемешиваем позиции
        nextSymbols.shuffle(_random);
      } else {
        // Для остальных случаев используем полностью случайную генерацию
        List<SlotSymbol> tempSymbols = List.from(_symbols);
        tempSymbols.shuffle(_random);
        nextSymbols = tempSymbols.sublist(0, min(3, tempSymbols.length));
      }

      _currentSymbols = nextSymbols;

      for (int i = 0; i < 3; i++) {
        List<SlotSymbol> temp = List.generate(_reelLength, (_) => _symbols[_random.nextInt(_symbols.length)]);
        temp[_centerIndex] = _currentSymbols[i];
        _reelSymbols[i] = temp;
      }

      _spinAnimationController.forward(from: 0.0);
    } catch (e) {
      debugPrint('Ошибка при вращении барабана: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при вращении барабана: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() {
        _isSpinning = false;
      });
    }
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
                      if (Provider.of<StyleProvider>(context, listen: false).selectedStyleId == 'slotstyle5')
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
                  if (Provider.of<StyleProvider>(context, listen: false).selectedStyleId == 'slotstyle5')
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
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Material(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                              child: Row(
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
                            if (_isFreeSpin) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  'Бесплатные прокрутки: $_freeSpins',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (_dodepTimerText.isNotEmpty && _dodepCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  _dodepTimerText,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildReel(index),
                  )),
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
                  onPressed: (_isFreeSpin || balanceProvider.balance <= 0) 
                      ? null 
                      : _showDepositDialog,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    backgroundColor: (_isFreeSpin || balanceProvider.balance <= 0)
                        ? Theme.of(context).colorScheme.surfaceVariant
                        : Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(
                    'Депнуть',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (_isFreeSpin || balanceProvider.balance <= 0)
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showAddBalanceNotification)
            _buildAddBalanceNotification(context),
          if (_showSadHorse)
            _buildSadHorseAnimation(),
        ],
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

  @override
  void dispose() {
    _dodepTimer?.cancel();
    _spinAnimationController.dispose();
    _winAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    _confettiController.dispose();
    _balanceProvider.removeListener(_checkBalanceForNotification);
    _saveDodepState();
    _audioPlayer.dispose();
    _autoSpinTimer?.cancel();
    super.dispose();
  }
} 