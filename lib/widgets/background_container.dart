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

    String? backgroundImage;
    
    switch (themeProvider.isFantasyGacha ? 'fantasy_gacha' : styleProvider.selectedStyleId) {
      case 'fantasy_gacha':
        backgroundImage = isDarkMode ? 'assets/images/fantasyBGnight.png' : 'assets/images/fantasyBG.png';
        break;
      case 'yamete':
        backgroundImage = isDarkMode ? 'assets/images/yameteBG.jpg' : 'assets/images/yameteBG2.png';
        break;
      case 'minecraft':
        backgroundImage = isDarkMode ? 'assets/images/minecraftBG2.png' : 'assets/images/minecraftBG.png';
        break;
      case 'lego':
        backgroundImage = isDarkMode ? 'assets/images/legoBG2.png' : 'assets/images/legoBG.png';
        break;
      case 'doka3':
        backgroundImage = isDarkMode ? 'assets/images/doka3BG2.png' : 'assets/images/doka3BG.png';
        break;
      case 'hellokitty':
        backgroundImage = isDarkMode ? 'assets/images/hkBG3.png' : 'assets/images/hkBG2.png';
        break;
      case 'tokyopuk':
        backgroundImage = isDarkMode ? 'assets/images/tokyopukBG2.png' : 'assets/images/tokyopukBG.png';
        break;
      default:
        backgroundImage = null;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundImage == null ? Theme.of(context).colorScheme.background : null,
        image: backgroundImage != null ? DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ) : null,
      ),
      child: child,
    );
  }
} 