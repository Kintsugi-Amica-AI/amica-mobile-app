import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A raised surface. Kept as the name ~15 screens already call; it is now
/// Blossom's frosted glass card — see [AmicaCard].
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
    this.borderColor,
    @Deprecated('Glass opacity comes from the theme. Ignored.')
    this.fillOpacity = 1.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  /// Tints the rim to mark a card as carrying a state — an active alert,
  /// say. Leave null for the default glass rim.
  final Color? borderColor;

  /// No longer has any effect.
  @Deprecated('Glass opacity comes from the theme. Ignored.')
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    return AmicaCard(
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      borderColor: borderColor,
      child: child,
    );
  }
}

/// Blossom's raised surface: real frosted glass.
///
/// Blurs the pastel washes behind it (so the card visibly takes on their
/// colour as it scrolls over them), lays a 60% white fill with a soft
/// top-left sheen on top, and draws a light-catching rim that is bright at
/// the top-left and fades toward the bottom-right — the cue that makes a
/// surface read as glass rather than as a white box.
///
/// Pass [color] for an opaque, tinted card instead (no blur).
class AmicaCard extends StatelessWidget {
  const AmicaCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.onTap,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final radius = BorderRadius.circular(borderRadius);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (color != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          border: Border.all(color: borderColor ?? c.lineSoft),
          boxShadow: c.shadow,
        ),
        child: content,
      );
    }

    // No per-card backdrop blur: blurring behind every card on every frame
    // made screens stutter during transitions and scrolling. Over the soft
    // radial washes the translucent fill + sheen + rim reads the same.
    return _Glass(
      radius: radius,
      blur: 0,
      fill: c.glassFill,
      borderColor: borderColor,
      child: content,
    );
  }
}

/// Real frosted glass for surfaces floating over busy content — the
/// journey sheets and the map / camera buttons. [strong] raises the fill so
/// text keeps full contrast over any map colour underneath.
class AmicaGlass extends StatelessWidget {
  const AmicaGlass({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = EdgeInsets.zero,
    this.blur = 22,
    this.strong = false,
    this.shape = BoxShape.rectangle,
    this.opacity,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool strong;
  final BoxShape shape;

  /// Overrides the fill's opacity (0–1) for a strong glass surface.
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final fill = strong || opacity != null
        ? Color.lerp(c.glassFill, c.card, 0.65)!.withValues(
            alpha: opacity ?? (c.shadow.isEmpty ? 0.86 : 0.82),
          )
        : c.glassFill;
    return _Glass(
      radius: shape == BoxShape.circle ? null : borderRadius,
      blur: blur,
      fill: fill,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The shared glass recipe: clip → blur what's behind → translucent fill
/// with a sheen → gradient rim.
class _Glass extends StatelessWidget {
  const _Glass({
    required this.radius,
    required this.blur,
    required this.fill,
    required this.child,
    this.borderColor,
  });

  /// Null means a circle.
  final BorderRadius? radius;
  final double blur;
  final Color fill;
  final Color? borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final isCircle = radius == null;

    final painted = CustomPaint(
        foregroundPainter: _GlassRimPainter(
          radius: radius,
          color: borderColor,
          bright: c.glassBorder,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(c.glassHighlight, fill),
                fill,
                fill.withValues(alpha: fill.a * 0.85),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: child,
        ),
      );

    // Real blur only where asked for (sheets over the map, the nav pill,
    // camera buttons) — it is the expensive part.
    if (blur <= 0) return painted;

    final layered = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: painted,
    );
    return isCircle
        ? ClipOval(child: layered)
        : ClipRRect(borderRadius: radius!, child: layered);
  }
}

/// A 1.2px rim that catches the light: bright top-left, fading to a whisper
/// bottom-right. A solid colour replaces it when a card marks a state.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.radius,
    required this.bright,
    this.color,
  });

  final BorderRadius? radius;
  final Color bright;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.2;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          bright,
          bright.withValues(alpha: bright.a * 0.35),
          bright.withValues(alpha: bright.a * 0.12),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Offset.zero & size);
    }
    if (radius == null) {
      canvas.drawOval(rect, paint);
    } else {
      canvas.drawRRect(radius!.toRRect(rect), paint);
    }
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.radius != radius || old.bright != bright || old.color != color;
}
