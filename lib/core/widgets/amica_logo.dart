import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Amica's brand mark.
///
/// Was a glowing gradient circle with a shield-and-moon glyph and a
/// letter-spaced all-caps wordmark under a neon shader. Warm Dawn states it
/// quietly: a flat blush disc, a single stroke shield, and the name set in
/// Bricolage Grotesque as ordinary words rather than shouted capitals.
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
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.blush,
          ),
          child: Icon(
            Icons.shield_outlined,
            color: c.terracottaDeep,
            size: size * 0.44,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(height: size * 0.22),
          Text(
            'Amica',
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 34),
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
