import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../providers/style_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';

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
    final styleProvider = Provider.of<StyleProvider>(context);
    final currentStyle = styleProvider.getStyleById(styleProvider.selectedStyleId);
    
    // Определяем цвета в зависимости от текущего стиля
    Color primaryColor;
    Color secondaryColor;
    
    switch (currentStyle.id) {
      case 'fantasy_gacha':
        primaryColor = isDark ? Color(0xFF20B2AA) : Color(0xFF008B8B);
        secondaryColor = isDark ? Color(0xFFE0FFFF) : Color(0xFF006666);
        break;
      case 'dresnya':
        primaryColor = isDark ? Colors.orange : Colors.deepOrange;
        secondaryColor = isDark ? Colors.deepOrange : Colors.orange;
        break;
      case 'tokyopuk':
        primaryColor = isDark ? Color(0xFF1A1A1A) : Color(0xFFB22222); // ghoulEye для темной темы, kaguneRed для светлой
        secondaryColor = isDark ? Color(0xFF1E1E1E) : Color(0xFFE31B23); // darkBlood для темной темы, bloodRed для светлой
        break;
      case 'lego':
        primaryColor = isDark ? Color(0xFF0055BF) : Color(0xFFE31837); // Синий для темной темы, красный для светлой
        secondaryColor = isDark ? Color(0xFF71C5CF) : Color(0xFFFFD700); // Светло-синий для темной темы, желтый для светлой
        break;
      case 'minecraft':
        primaryColor = isDark ? Colors.green : Colors.lightGreen;
        secondaryColor = isDark ? Colors.lightGreen : Colors.green;
        break;
      case 'doka3':
        primaryColor = isDark ? Color(0xFFC23C2A) : Color(0xFF4CAF50); // Красный для темной темы, зеленый для светлой
        secondaryColor = isDark ? Color(0xFF8B0000) : Color(0xFF81C784); // Темно-красный для темной темы, светло-зеленый для светлой
        break;
      case 'yamete':
        primaryColor = isDark ? Colors.red : Colors.pink;
        secondaryColor = isDark ? Colors.pink : Colors.red;
        break;
      case 'hellokitty':
        primaryColor = isDark ? Color(0xFFFF69B4) : Color(0xFFFFB6C1); // Hello Kitty Pink
        secondaryColor = isDark ? Color(0xFFFFB6C1) : Color(0xFFFF69B4); // Light Pink
        break;
      default: // classic
        primaryColor = isDark ? Colors.deepPurple : Colors.purple;
        secondaryColor = isDark ? Colors.purple : Colors.pink;
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentStyle.id == 'doka3' 
                  ? Color(0xFF2A2A2A) // dotaMenuGray
                  : currentStyle.id == 'tokyopuk'
                      ? isDark
                          ? Color(0xFF8B0000) // darkSurface
                          : Color(0xFF1A1A1A) // lightSurface
                      : colorScheme.surface,
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
                      primaryColor,
                      secondaryColor,
                    ),
                    _buildNavItem(
                      context,
                      'assets/images/slots_icon.png',
                      'assets/images/slots_icon.png',
                      1,
                      isDark,
                      primaryColor,
                      secondaryColor,
                    ),
                    _buildNavItem(
                      context,
                      'assets/images/style_icon.png',
                      'assets/images/style_icon.png',
                      2,
                      isDark,
                      primaryColor,
                      secondaryColor,
                    ),
                    _buildNavItem(
                      context,
                      'assets/images/profile_icon.png',
                      'assets/images/profile_icon.png',
                      3,
                      isDark,
                      primaryColor,
                      secondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (currentStyle.id == 'minecraft')
            Positioned(
              top: -50,
              right: -20,
              child: IgnorePointer(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: Image.asset(
                  'assets/images/ghast.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          if (currentStyle.id == 'minecraft')
            Positioned(
              top: 45,
              right: 325,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/earth.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (currentStyle.id == 'doka3')
            Positioned(
              top: 0,
              right: -32,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationX(pi),
                  child: Image.asset(
                    'assets/images/desolator.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'doka3' && !isDark)
            Positioned(
              top: -35,
              right: 110,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/blade.png',
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'doka3' && isDark)
            Positioned(
              top: -40,
              right: 121,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/agan.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'doka3')
            Positioned(
              top: -30,
              right: 295,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/hex.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (currentStyle.id == 'yamete')
            Positioned(
              top: -25,
              right: 65,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(30 * pi / 180),
                  child: Image.asset(
                    'assets/images/sakuraflower.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'yamete')
            Positioned(
              top: -15, 
              left: 50,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(90 * pi / 180),
                  child: Image.asset(
                    'assets/images/sakuraflower.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'yamete')
            Positioned(
              top: 55, 
              right: 36,
              left: 0,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationZ(-10 * pi / 180),
                  child: Image.asset(
                    'assets/images/sakuraflower.png',
                    width: 35,
                    height: 35,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'tokyopuk')
            Positioned(
              top: -15, 
              right: -40,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/centipede.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'fantasy_gacha' && isDark)
            Positioned(
              top: -20,
              right: 121,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/sword2.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'fantasy_gacha' && !isDark)
            Positioned(
              top: -20,
              right: 121,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/sword.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            if (currentStyle.id == 'fantasy_gacha')
            Positioned(
              top: -70, 
              right: -10,
              child: IgnorePointer(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity(),
                  child: Image.asset(
                    'assets/images/cat.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String outlinedIcon,
    String filledIcon,
    int index,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final isSelected = selectedIndex == index;
    
    // Определяем цвета градиента в зависимости от темы и стиля
    final gradientColors = isDark
        ? [
            primaryColor.withOpacity(0.25),
            secondaryColor.withOpacity(0.25),
          ]
        : [
            primaryColor.withOpacity(0.15),
            secondaryColor.withOpacity(0.15),
          ];

    final iconGradientColors = isDark
        ? [
            primaryColor,
            secondaryColor,
          ]
        : [
            primaryColor,
            secondaryColor,
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
                        ? secondaryColor.withOpacity(0.3)
                        : primaryColor.withOpacity(0.3),
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
                                ? secondaryColor.withOpacity(0.4)
                                : primaryColor.withOpacity(0.4),
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