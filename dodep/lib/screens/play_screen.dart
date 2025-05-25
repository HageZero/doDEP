import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import '../widgets/slot_reel.dart'; // Импортируем виджет барабана
import 'dart:math'; // Для генерации случайных чисел
import 'dart:async';
import 'package:collection/collection.dart'; // Для shuffle
import 'package:confetti/confetti.dart'; // Импортируем пакет confetti
import 'package:flutter/rendering.dart';
import 'dart:ui'; // Добавляем импорт для ImageFilter
import 'package:shared_preferences/shared_preferences.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  // Список всех возможных символов (эмодзи и изображения)
  final List<String> _symbols = [
    '🍒', // Вишня
    '🍋', // Лимон
    '🍊', // Апельсин
    '🍇', // Виноград
    '🍎', // Яблоко
    '🍓', // Клубника
    'assets/images/emerald.png', // Изумруд
    'assets/images/hkslot.png', // HK Slot
    'assets/images/primogem.png', // Примогем
    'assets/images/rbface.png', // RB Face
  ];

  // Текущие символы на барабанах
  List<String> _currentSymbols = [
    '🍒', // Начальный символ для барабана 1
    '🍒', // Начальный символ для барабана 2
    '🍒', // Начальный символ для барабана 3
  ];

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
  late List<List<String>> _reelSymbols;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _balanceProvider = Provider.of<BalanceProvider>(context);
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
      duration: const Duration(seconds: 5),
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

  void _handleDodep() {
    if (!_canDodep()) {
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

  void _checkWin() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    
    if (_currentSymbols[0] == _currentSymbols[1] && _currentSymbols[1] == _currentSymbols[2]) {
      int winAmount = _currentBet * 2;
      await balanceProvider.addBalance(winAmount);
      setState(() {
        _winMessage = 'ДЖЕКПОТ $winAmount!';
        _showWinMessage = true;
        _isBigWin = true;
      });
      _winAnimationController.forward(from: 0.0);
      _rotationAnimationController.repeat(reverse: true);
      _confettiController.play();
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showWinMessage = false;
            _rotationAnimationController.stop();
          });
        }
      });
    } else if (_currentSymbols[0] == _currentSymbols[1] || 
               _currentSymbols[1] == _currentSymbols[2] || 
               _currentSymbols[0] == _currentSymbols[2]) {
      int winAmount = _currentBet;
      await balanceProvider.addBalance(winAmount);
      setState(() {
        _winMessage = 'Вы выиграли $winAmount!';
        _showWinMessage = true;
        _isBigWin = false;
      });
    } else {
      _isBigWin = false;
    }
    _checkBalanceForNotification();
  }

  void _spinReels() async {
    final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
    
    if (_isSpinning || _winAnimationController.isAnimating) return;
    if (balanceProvider.balance <= 0) {
       _checkBalanceForNotification();
      return;
    }
    if (balanceProvider.balance < _currentBet) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Недостаточно средств для спина!')),
      );
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

    await balanceProvider.subtractBalance(_currentBet);

    double randomValue = _random.nextDouble();
    List<String> nextSymbols = [];

    if (randomValue < _prob3Same) {
      String symbol = _symbols[_random.nextInt(_symbols.length)];
      nextSymbols = [symbol, symbol, symbol];
    } else if (randomValue < _prob3Same + _prob2Same) {
      String symbol1 = _symbols[_random.nextInt(_symbols.length)];
      String symbol2;
      do {
        symbol2 = _symbols[_random.nextInt(_symbols.length)];
      } while (symbol2 == symbol1);

      nextSymbols = [symbol1, symbol1, symbol2];
      nextSymbols.shuffle(_random);
    } else {
      List<String> tempSymbols = List.from(_symbols);
      tempSymbols.shuffle(_random);
      nextSymbols = tempSymbols.sublist(0, min(3, tempSymbols.length));

       while (nextSymbols.toSet().length < min(3, _symbols.length) && _symbols.length >=3) {
           tempSymbols = List.from(_symbols);
           tempSymbols.shuffle(_random);
           nextSymbols = tempSymbols.sublist(0, min(3, tempSymbols.length));
       }
       if (_symbols.length < 3) {
          if (_symbols.length == 2) {
             nextSymbols = [_symbols[_random.nextInt(2)], _symbols[_random.nextInt(2)], _symbols[_random.nextInt(2)]];
          } else if (_symbols.length == 1) {
             nextSymbols = [_symbols[0], _symbols[0], _symbols[0]];
          }
       }
    }

    _currentSymbols = nextSymbols;

    for (int i = 0; i < 3; i++) {
      List<String> temp = List.generate(_reelLength, (_) => _symbols[_random.nextInt(_symbols.length)]);
      temp[_centerIndex] = _currentSymbols[i];
      _reelSymbols[i] = temp;
    }

    _spinAnimationController.forward(from: 0.0);
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  'Выберите ставку',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildBetButton(50),
                    _buildBetButton(100),
                    _buildBetButton(300),
                    _buildBetButton(500),
                    _buildBetButton(1000),
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
  }

  Widget _buildBetButton(int amount) {
    final isSelected = amount == _currentBet;
    final color = Theme.of(context).colorScheme.primary;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentBet = amount;
        });
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.1),
        foregroundColor: isSelected ? Theme.of(context).colorScheme.onPrimary : color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color),
        ),
      ),
      child: Text(
        '+$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Виджет уведомления о низком балансе
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
                          onPressed: _canDodep() ? _handleDodep : null,
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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _isBigWin
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surface,
                          _isBigWin
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: _currentSymbols[index].startsWith('assets/')
                        ? Image.asset(_currentSymbols[index], height: 60, width: 60, fit: BoxFit.contain)
                        : Center(child: Text(_currentSymbols[index], style: TextStyle(fontSize: 40))),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return AnimatedBuilder(
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
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: _reelSymbols[index][symbolIndex].startsWith('assets/')
                      ? Image.asset(_reelSymbols[index][symbolIndex], height: 60, width: 60, fit: BoxFit.contain)
                      : Text(_reelSymbols[index][symbolIndex], style: TextStyle(fontSize: 40)),
                ),
              ));
            }
          }
          return Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Stack(children: stackChildren),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Scaffold(
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
                      if (_dodepTimerText.isNotEmpty) ...[
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
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    // Виджет конфетти, расположенный сверху
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.tertiary,
                          Colors.red, Colors.green, Colors.blue, Colors.yellow,
                        ],
                        emissionFrequency: 0.05,
                        numberOfParticles: 50,
                        gravity: 0.1,
                        minimumSize: const Size(10,10),
                        maximumSize: const Size(20,20),
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
                            onPressed: _isSpinning || _winAnimationController.isAnimating ? null : _spinReels,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              _isSpinning ? 'Крутится...' : 'Крутить! (${_currentBet})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: balanceProvider.balance > 0 ? _showDepositDialog : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                              backgroundColor: balanceProvider.balance > 0 
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            child: Text(
                              'Депнуть',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: balanceProvider.balance > 0 
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                     if (_showAddBalanceNotification) // Показываем уведомление, если нужно
                       _buildAddBalanceNotification(context),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    super.dispose();
  }
} 