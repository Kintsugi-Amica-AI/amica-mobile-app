import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Amica's in-app brand mark: a glowing gradient shield with a spark,
/// used on auth and splash-style moments. Built entirely from vector
/// primitives so no image assets are required.
class AmicaLogo extends StatelessWidget {
  const AmicaLogo({super.key, this.size = 84, this.showWordmark = true});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.auraGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.shield_moon_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryButtonGradient.createShader(bounds),
            child: const Text(
              'AMICA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your AI Safety Companion',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
