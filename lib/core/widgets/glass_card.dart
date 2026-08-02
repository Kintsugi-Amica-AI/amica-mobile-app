import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted "glassmorphic" container used throughout Amica for cards,
/// panels, and grouped content over the gradient background.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 22,
    this.onTap,
    this.borderColor,
    this.fillOpacity = 0.06,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Colors.white.withValues(alpha: fillOpacity),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: (borderColor ?? Colors.white).withValues(
                    alpha: borderColor == null ? 0.12 : 0.4,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
