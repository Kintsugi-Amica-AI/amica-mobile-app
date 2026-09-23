import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The app's ground.
///
/// Previously this painted a violet gradient with three blurred neon glow
/// blobs. Warm Dawn is flat: a single ivory surface, no gradient, no glow.
/// Depth comes from the one soft shadow on raised cards, and nothing else
/// on a screen is allowed to compete with the SOS control.
///
/// Kept as a widget rather than deleted so screens have one place to say
/// "this is an Amica surface", and so the ground can be adjusted centrally.
class AmicaBackground extends StatelessWidget {
  const AmicaBackground({
    required this.child,
    super.key,
    @Deprecated('Warm Dawn has no glow. Ignored.') this.showGlow = false,
  });

  final Widget child;

  /// No longer has any effect. Retained so existing call sites keep
  /// compiling; remove the argument when you touch a screen.
  @Deprecated('Warm Dawn has no glow. Ignored.')
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).amica.ivory,
      child: child,
    );
  }
}
