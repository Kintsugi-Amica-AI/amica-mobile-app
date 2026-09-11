import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared gradient backdrop with soft neon glow blobs used behind the
/// hero screens (auth, home, journey, SOS) to give Amica a cohesive,
/// futuristic feel.
class AmicaBackground extends StatelessWidget {
  const AmicaBackground({
    required this.child,
    super.key,
    this.showGlow = true,
  });

  final Widget child;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showGlow) ...const [
            _GlowBlob(
              color: AppColors.primary,
              alignment: Alignment(-1.2, -1.0),
              size: 280,
            ),
            _GlowBlob(
              color: AppColors.secondary,
              alignment: Alignment(1.3, -0.6),
              size: 240,
            ),
            _GlowBlob(
              color: AppColors.alert,
              alignment: Alignment(1.1, 1.2),
              size: 260,
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.alignment,
    required this.size,
  });

  final Color color;
  final Alignment alignment;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
