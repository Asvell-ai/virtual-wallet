import 'package:flutter/material.dart';

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    required this.child,
    this.offset = 20,
    this.duration = const Duration(milliseconds: 450),
    super.key,
  });

  final Widget child;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        ),
      );
}
