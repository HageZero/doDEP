import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/style_provider.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final styleProvider = Provider.of<StyleProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (themeProvider.isFantasyGacha) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDarkMode ? 'assets/images/fantasyBGnight.png' : 'assets/images/fantasyBG.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
    } else if (styleProvider.selectedStyleId == 'yamete') {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDarkMode ? 'assets/images/yameteBG.jpg' : 'assets/images/yameteBG2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
    } else if (styleProvider.selectedStyleId == 'minecraft') {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDarkMode ? 'assets/images/minecraftBG2.png' : 'assets/images/minecraftBG.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
    } else {
      // Для остальных тем используем один цвет фона
      return Container(
        color: Theme.of(context).colorScheme.background,
        child: child,
      );
    }
  }
} 