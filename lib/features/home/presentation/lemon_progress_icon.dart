import 'package:flutter/material.dart';

class LemonProgressIcon extends StatelessWidget {
  const LemonProgressIcon({required this.filled, super.key});

  final bool filled;

  static const double size = 26;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: filled ? 1 : 0.28,
        child: const Text('🍋', style: TextStyle(fontSize: 22, height: 1.1)),
      ),
    );
  }
}
