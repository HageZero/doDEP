import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/style_provider.dart';

class StyleScreen extends StatelessWidget {
  const StyleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final styleProvider = Provider.of<StyleProvider>(context);
    final boughtStyles = styleProvider.allSlotStyles.where((style) => styleProvider.isStyleBought(style.id)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Надристать стиля',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: boughtStyles.length,
                itemBuilder: (context, index) {
                  final style = boughtStyles[index];
                  final isSelected = style.id == styleProvider.selectedStyleId;

                  return Card(
                    elevation: isSelected ? 4 : 0,
                    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      onTap: () {
                        styleProvider.selectStyle(style.id);
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Expanded(
                            child: Image.asset(
                              style.imageAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            style.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                             textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (isSelected)
                             Text(
                              'Выбрано',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
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
    );
  }
} 