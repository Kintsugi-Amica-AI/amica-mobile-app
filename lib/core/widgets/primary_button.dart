import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// What an Amica button means, by colour.
enum AmicaButtonTone {
  /// Default. Plum — the ordinary "continue" action.
  primary,

  /// Shell with a hairline. A secondary choice sitting beside a primary one.
  quiet,

  /// Terracotta. Reserved for actions that summon help. Nothing else in the
  /// app may use this tone, so it never loses its meaning.
  danger,

  /// Sage. Confirming safety — "I'm safe", "end journey".
  safe,
}

/// Amica's action button: flat fill, 16px radius, 54px tall.
///
/// The old version was a violet-to-cyan gradient with a 20px neon glow.
/// Warm Dawn has no gradients and no glow — hierarchy is carried by colour
/// and position instead, which survives being looked at in a hurry.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.tone = AmicaButtonTone.primary,
    this.isBusy = false,
    this.height = 54,
    @Deprecated('Use tone: AmicaButtonTone.danger') bool isDanger = false,
  }) : _legacyDanger = isDanger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AmicaButtonTone tone;

  /// Swaps the label for a spinner and blocks taps. Use this rather than
  /// retitling the button "Sending…" — the control stays the same size, so
  /// nothing below it jumps while a request is in flight.
  final bool isBusy;

  final double height;
  final bool _legacyDanger;

  AmicaButtonTone get _tone =>
      _legacyDanger ? AmicaButtonTone.danger : tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final enabled = onPressed != null && !isBusy;

    final (Color bg, Color fg, Color? border) = switch (_tone) {
      AmicaButtonTone.primary => (c.plum, c.ivory, null),
      AmicaButtonTone.quiet => (c.shell, c.plum, c.line),
      AmicaButtonTone.danger => (c.terracotta, AppColors.onTerracotta, null),
      AmicaButtonTone.safe => (c.sage, AppColors.onSage, null),
    };

    return Opacity(
      opacity: enabled || isBusy ? 1 : 0.45,
      child: SizedBox(
        height: height,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: border == null ? null : Border.all(color: border),
              ),
              child: Center(
                child: isBusy
                    ? SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(fg),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: fg, size: 20),
                            const SizedBox(width: 9),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.08,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
