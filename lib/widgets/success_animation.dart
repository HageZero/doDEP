import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;

  const SuccessAnimation({
    super.key,
    this.onComplete,
    this.size = 200,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/successful_anim.json',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        controller: _controller,
        animate: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
} 