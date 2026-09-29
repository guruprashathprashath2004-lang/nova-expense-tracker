import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/glass/glass.dart';

class HomeTabFrame extends StatelessWidget {
  const HomeTabFrame({
    required this.title,
    required this.subtitle,
    required this.children,
    this.onRefresh,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.md),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        ...children,
      ],
    );
    final refresh = onRefresh;
    return refresh == null
        ? content
        : RefreshIndicator(onRefresh: refresh, child: content);
  }
}
