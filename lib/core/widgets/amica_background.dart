import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The app's ground: Blossom's soft pastel wash.
///
/// A near-white base with three large, heavily-blurred washes — rose top
/// right, lavender mid left, peach bottom right — the airy gradient ground
/// of the reference designs. In dark mode the same washes are deep and very
/// faint, so the screen stays matte and discreet.
///
/// Every page route is already wrapped in this by the theme's page
/// transitions builder, so screens rarely need to use it directly. Nested
/// uses are harmless: an inner [AmicaBackground] detects the outer one and
/// paints nothing, so the washes never double up.
class AmicaBackground extends StatelessWidget {
  const AmicaBackground({
    required this.child,
    super.key,
    @Deprecated('The glow is now part of the ground. Ignored.')
    this.showGlow = false,
  });

  final Widget child;

  /// No longer has any effect. Retained so existing call sites keep
  /// compiling; remove the argument when you touch a screen.
  @Deprecated('The glow is now part of the ground. Ignored.')
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    if (_AmicaGroundMarker.of(context)) return child;

    final c = Theme.of(context).amica;

    return _AmicaGroundMarker(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.ivory,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(c.ivory, c.glowLavender, 0.35)!,
              c.ivory,
              c.ivory,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WashPainter(
                    rose: c.glowRose,
                    lavender: c.glowLavender,
                    peach: c.glowPeach,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _AmicaGroundMarker extends InheritedWidget {
  const _AmicaGroundMarker({required super.child});

  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AmicaGroundMarker>() != null;

  @override
  bool updateShouldNotify(_AmicaGroundMarker oldWidget) => false;
}

/// Radial washes, cheaper than blurred containers and identical on every
/// frame, so the whole ground sits behind a [RepaintBoundary].
class _WashPainter extends CustomPainter {
  const _WashPainter({
    required this.rose,
    required this.lavender,
    required this.peach,
  });

  final Color rose;
  final Color lavender;
  final Color peach;

  void _wash(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _wash(canvas, Offset(w * 1.0, h * 0.02), w * 0.85, rose);
    _wash(canvas, Offset(w * -0.1, h * 0.38), w * 0.75, lavender);
    _wash(canvas, Offset(w * 0.95, h * 0.95), w * 0.8, peach);
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.rose != rose || old.lavender != lavender || old.peach != peach;
}
