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
              Color.lerp(c.ivory, c.glowLavender, 0.25)!,
              c.ivory,
              Color.lerp(c.ivory, c.glowPeach, 0.2)!,
            ],
            stops: const [0, 0.5, 1],
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
                    sky: c.glowSky,
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
    required this.sky,
  });

  final Color rose;
  final Color lavender;
  final Color peach;
  final Color sky;

  void _wash(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Spread down the whole screen, so every card has colour behind it
    // for the frosted glass to pick up.
    _wash(canvas, Offset(w * 1.02, h * 0.06), w * 0.95, rose);
    _wash(canvas, Offset(w * -0.12, h * 0.36), w * 0.9, lavender);
    _wash(canvas, Offset(w * 1.1, h * 0.63), w * 0.8, sky);
    _wash(canvas, Offset(w * 0.08, h * 0.98), w * 0.95, peach);
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.rose != rose ||
      old.lavender != lavender ||
      old.peach != peach ||
      old.sky != sky;
}
