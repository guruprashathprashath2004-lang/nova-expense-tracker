import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? tintOverride;
  final bool showBorder;
  final bool showShadow;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.card,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.blurSigma = GlassTokens.blurSigma,
    this.tintOverride,
    this.showBorder = true,
    this.showShadow = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = tintOverride ??
        (isDark
            ? Colors.white.withValues(alpha: GlassTokens.surfaceOpacityDark)
            : Colors.white.withValues(alpha: GlassTokens.surfaceOpacityLight));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: GlassTokens.borderOpacity)
        : Colors.black.withValues(alpha: GlassTokens.borderOpacity * 0.6);

    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: radius,
            border:
                showBorder ? Border.all(color: borderColor, width: 1) : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );

    if (showShadow) {
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: GlassTokens.shadowOpacity),
              blurRadius: GlassTokens.shadowBlur,
              spreadRadius: GlassTokens.shadowSpread,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: content,
      );
    } else if (margin != null) {
      content = Container(margin: margin, child: content);
    }

    return content;
  }
}
