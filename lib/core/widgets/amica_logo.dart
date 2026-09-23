import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Amica's brand mark.
///
/// Blossom: a lavender → orchid gradient disc with a shield-and-moon glyph
/// on a soft lavender halo, and the name in Bricolage Grotesque carrying the
/// same gradient. Deliberately not rose — rose is reserved for emergency.
///
/// Still pure vector — no image asset required.
class AmicaLogo extends StatelessWidget {
  const AmicaLogo({
    super.key,
    this.size = 72,
    this.showWordmark = true,
    this.tagline = 'Someone knows where you are',
  });

  final double size;
  final bool showWordmark;

  /// The line under the wordmark. Says what the app does for you, rather
  /// than what it is built from.
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Soft lavender halo, then the brand-gradient disc.
        Container(
          width: size * 1.3,
          height: size * 1.3,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.accentSoft,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: c.accentGradient,
              boxShadow: c.accentGlow,
            ),
            child: Icon(
              Icons.shield_moon_outlined,
              color: AppColors.onAccent,
              size: size * 0.46,
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.22),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => c.accentGradient.createShader(bounds),
            child: Text(
              'Amica',
              style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
