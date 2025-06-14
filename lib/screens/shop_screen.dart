import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import '../providers/style_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/success_animation.dart';
import '../widgets/app_scaffold.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _showSuccessAnimation = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUI();
    });
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    final styleProvider = Provider.of<StyleProvider>(context);
    final availableStyles = styleProvider.allSlotStyles.where((style) => style.price != null).toList(); // Только те стили, у которых есть цена

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
                        'Магазин',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Consumer<BalanceProvider>(
                        builder: (context, balanceProvider, _) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20.0),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 элемента в ряду
                        crossAxisSpacing: 16, // Расстояние по горизонтали
                        mainAxisSpacing: 16, // Расстояние по вертикали
                        childAspectRatio: 0.8, // Соотношение сторон элементов (можно настроить)
                      ),
                      itemCount: availableStyles.length,
                      itemBuilder: (context, index) {
                        final style = availableStyles[index];
                        final isBought = styleProvider.isStyleBought(style.id);

                        return Card(
                          elevation: 4,
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                                onTap: () async {
                              final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
                              if (!isBought) {
                                if (balanceProvider.balance >= style.price!) {
                                  debugPrint('[ShopScreen] Покупка стиля: updateBalance(-${style.price!})');
                                  balanceProvider.updateBalance(-(style.price!));
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (!_isOffline) {
                                    final localSuccess = await styleProvider.buyStyle(style);
                                    // Показываем анимацию успеха, если локально куплено (даже если нет интернета)
                                    if (localSuccess) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) setState(() => _showSuccessAnimation = true);
                                      });
                                      // Скрываем анимацию через 2 секунды
                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (mounted) {
                                          setState(() {
                                            _showSuccessAnimation = false;
                                          });
                                        }
                                      });
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Стиль ${style.name} куплен!'),
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                          ),
                                        );
                                      }
                                    } else {
                                      // Если не удалось купить (например, баг), возвращаем баланс
                                      balanceProvider.updateBalance(style.price!);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Ошибка при покупке стиля ${style.name}'),
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Недостаточно изумрудов для покупки стиля ${style.name}'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                  child: Image.asset(
                                    style.imageAsset,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Theme.of(context).colorScheme.errorContainer,
                                            child: Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                color: Theme.of(context).colorScheme.error,
                                                size: 32,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  style.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                if (isBought) // Если куплено
                                  Text(
                                    'Куплено',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ) else // Если не куплено, показываем цену
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/emerald.png',
                                        height: 16,
                                        width: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${style.price}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccessAnimation)
            const SuccessAnimation(),
        ],
      ),
    );
  }
} 