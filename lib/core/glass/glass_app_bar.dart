import 'package:flutter/material.dart';
import '../constants.dart';
import 'glass_container.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? accent;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.accent,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: SafeArea(
        bottom: false,
        child: GlassContainer(
          borderRadius: AppRadius.pill,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          height: 56,
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading == null) const SizedBox(width: AppSpacing.sm),
              if (accent != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions!,
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
