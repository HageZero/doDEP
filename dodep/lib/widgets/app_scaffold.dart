import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'background_container.dart';
import '../providers/theme_provider.dart';
import '../providers/style_provider.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.extendBody = true,
    this.extendBodyBehindAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final styleProvider = Provider.of<StyleProvider>(context);
    
    // Проверяем, есть ли фоновая картинка
    final bool hasBackgroundImage = themeProvider.isFantasyGacha || 
                                  styleProvider.selectedStyleId == 'yamete' ||
                                  styleProvider.selectedStyleId == 'minecraft' ||
                                  styleProvider.selectedStyleId == 'lego' ||
                                  styleProvider.selectedStyleId == 'doka3' ||
                                  styleProvider.selectedStyleId == 'hellokitty'||
                                  styleProvider.selectedStyleId == 'tokyopuk';
    
    return BackgroundContainer(
      child: Container(
        decoration: BoxDecoration(
          color: hasBackgroundImage ? Colors.black.withOpacity(0.6) : Colors.transparent,
        ),
        child: Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          backgroundColor: backgroundColor ?? Colors.transparent,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        ),
      ),
    );
  }
} 