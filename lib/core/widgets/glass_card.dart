import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A raised surface. Kept as the name ~15 screens already call; it is now
/// Blossom's frosted card — see [AmicaCard].
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

/// Blossom's raised surface: frosted glass.
///
/// A translucent fill with a soft top-left sheen, a bright glass rim and a
/// faint tinted shadow. Over the app's smooth pastel ground a real backdrop
/// blur would look identical and cost a blur pass per card, so this card
/// fakes it; use [AmicaGlass] where there is real detail behind the surface
/// (maps, photos, scrolled content).
///
/// Pass [color] for an opaque, tinted card instead.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? c.glassGradient : null,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? c.glassBorder),
        boxShadow: c.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Real frosted glass: blurs whatever is behind it.
///
/// For surfaces floating over busy content — the journey sheets and the map
/// controls. [strong] raises the fill so text stays at full contrast over
/// any map colour underneath.
class AmicaGlass extends StatelessWidget {
  const AmicaGlass({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = EdgeInsets.zero,
    this.blur = 22,
    this.strong = false,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final bool strong;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final fill = strong
        ? Color.lerp(c.glassFill, c.card, 0.6)!.withValues(
            alpha: c.shadow.isEmpty ? 0.88 : 0.86,
          )
        : c.glassFill;
    final isCircle = shape == BoxShape.circle;

    final surface = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: isCircle ? null : borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.alphaBlend(c.glassHighlight, fill), fill],
          ),
          border: Border.all(color: c.glassBorder),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: isCircle ? null : borderRadius,
        boxShadow: c.shadow,
      ),
      child: isCircle
          ? ClipOval(child: surface)
          : ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}
