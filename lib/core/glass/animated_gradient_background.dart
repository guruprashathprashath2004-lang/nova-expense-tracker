import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final Duration period;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 24),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final blobColors = isDark
        ? const [Color(0xFF2B2E6B), Color(0xFF4A2B6B), Color(0xFF6B2B52)]
        : const [Color(0xFFCFE0FF), Color(0xFFE3D2FF), Color(0xFFFFD9EC)];

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _BlobPainter(
                  t: _controller.value,
                  colors: blobColors,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        // Blur pass so the blobs read as soft frosted light, not hard shapes.
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.expand(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final bool isDark;

  _BlobPainter({required this.t, required this.colors, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(
      isDark ? const Color(0xFF0E1116) : const Color(0xFFEFF3FB),
      BlendMode.src,
    );

    final angle = t * 2 * math.pi;
    final positions = <Offset>[
      Offset(
        size.width * (0.25 + 0.15 * math.sin(angle)),
        size.height * (0.20 + 0.10 * math.cos(angle)),
      ),
      Offset(
        size.width * (0.75 + 0.12 * math.cos(angle * 0.8)),
        size.height * (0.35 + 0.12 * math.sin(angle * 0.8)),
      ),
      Offset(
        size.width * (0.5 + 0.18 * math.sin(angle * 0.6 + 1.5)),
        size.height * (0.80 + 0.10 * math.cos(angle * 0.6)),
      ),
    ];

    for (var i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i].withValues(alpha: isDark ? 0.55 : 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
      canvas.drawCircle(positions[i], size.width * 0.35, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}
