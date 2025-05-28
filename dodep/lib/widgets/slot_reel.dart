import 'package:flutter/material.dart';
import '../models/slot_symbol.dart';

class SlotReel extends StatelessWidget {
  final SlotSymbol symbol;
  final double size;

  const SlotReel({
    Key? key,
    required this.symbol,
    this.size = 100.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0),
        child: Image.asset(
          symbol.imagePath,
          fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: size * 0.3,
              ),
            );
          },
              ),
      ),
    );
  }
} 