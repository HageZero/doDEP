import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  'assets/images/shop_icon.png',
                  'assets/images/shop_icon.png',
                  0,
                  isDark,
                ),
                _buildNavItem(
                  context,
                  'assets/images/slots_icon.png',
                  'assets/images/slots_icon.png',
                  1,
                  isDark,
                ),
                _buildNavItem(
                  context,
                  'assets/images/style_icon.png',
                  'assets/images/style_icon.png',
                  2,
                  isDark,
                ),
                _buildNavItem(
                  context,
                  'assets/images/profile_icon.png',
                  'assets/images/profile_icon.png',
                  3,
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String outlinedIcon,
    String filledIcon,
    int index,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedIndex == index;
    
    // Определяем цвета градиента в зависимости от темы
    final gradientColors = isDark
        ? [
            Colors.deepPurple.withOpacity(0.25),
            Colors.purple.withOpacity(0.25),
          ]
        : [
            Colors.pink.withOpacity(0.15),
            Colors.purple.withOpacity(0.15),
          ];

    final iconGradientColors = isDark
        ? [
            Colors.deepPurple,
            Colors.purple,
          ]
        : [
            Colors.pink,
            Colors.purple,
          ];
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: isDark 
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.pink.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isSelected
                    ? ShaderMask(
                        key: ValueKey<int>(index),
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: iconGradientColors,
                        ).createShader(bounds),
                        child: Image.asset(
                          filledIcon,
                          width: 28,
                          height: 28,
                          color: Colors.white,
                        ),
                      )
                    : Image.asset(
                        key: ValueKey<int>(index),
                        outlinedIcon,
                        width: 28,
                        height: 28,
                        color: isDark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
              ),
              if (isSelected)
                Positioned(
                  bottom: -12,
                  child: Transform.rotate(
                    angle: 3.14159, // 180 градусов
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: iconGradientColors,
                      ).createShader(bounds),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 20,
                        shadows: [
                          Shadow(
                            color: isDark
                                ? Colors.purple.withOpacity(0.4)
                                : Colors.pink.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 