import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCounterText extends StatelessWidget {
  final double value;
  final String currencySymbol;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounterText({
    super.key,
    required this.value,
    required this.currencySymbol,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          formatter.format(animatedValue),
          style: style ??
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
        );
      },
    );
  }
}
