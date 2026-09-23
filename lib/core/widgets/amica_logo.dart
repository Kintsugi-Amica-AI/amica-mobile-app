import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Amica's brand mark: the app logo (shield, profile and caring hand, with
/// the AMICA wordmark and "Your safety, our mission"), shown as a rounded
/// tile that floats on a soft brand-coloured glow.
///
/// The artwork is `assets/images/amica_logo.png` — the launcher icon's
/// picture with its corners made transparent.
class AmicaLogo extends StatelessWidget {
  const AmicaLogo({super.key, this.size = 148});

  final double size;

  static const String asset = 'assets/images/amica_logo.png';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final radius = BorderRadius.circular(size * 0.2);
    return Semantics(
      image: true,
      label: 'Amica',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: c.accentEnd.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
