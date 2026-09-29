import 'package:flutter/material.dart';
import '../constants.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double limit;
  final String? label;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.limit,
    this.label,
  });

  double get _ratio => limit <= 0 ? 0 : (spent / limit).clamp(0, 1.5);

  Color _colorFor(BuildContext context) {
    if (_ratio >= 1.0) return const Color(0xFFE5484D);
    if (_ratio >= 0.8) return const Color(0xFFF7B84F);
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Stack(
            children: [
              Container(
                height: 10,
                color: color.withValues(alpha: 0.15),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _ratio.clamp(0, 1.0).toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 10, color: color),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
