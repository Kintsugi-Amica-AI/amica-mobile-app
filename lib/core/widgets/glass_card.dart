import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A raised surface.
///
/// Formerly a frosted `BackdropFilter` panel over a gradient. That is gone:
/// blurred translucent white over a coloured ground never cleared 4.5:1 on
/// its own text, and this app gets read one-handed, at night, under stress.
///
/// Warm Dawn's card is opaque — solid surface, hairline border, one soft
/// shadow. The class name is kept so the ~15 screens still calling it keep
/// working; new code should prefer [AmicaCard].
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
    this.borderColor,
    @Deprecated('Warm Dawn cards are opaque. Ignored.') this.fillOpacity = 1.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  /// Tints the border to mark a card as carrying a state — an active alert,
  /// say. Leave null for the default hairline.
  final Color? borderColor;

  /// No longer has any effect.
  @Deprecated('Warm Dawn cards are opaque. Ignored.')
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

/// Warm Dawn's raised surface: opaque fill, hairline border, soft shadow.
class AmicaCard extends StatelessWidget {
  const AmicaCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
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
        color: color ?? c.card,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? c.lineSoft),
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
