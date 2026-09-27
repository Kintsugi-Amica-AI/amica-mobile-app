import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'google_logo.dart';
import 'motion.dart';

/// Shared pieces of the sign-in and sign-up screens.

/// "Continue with Google": a white pill with Google's four-colour G, as
/// Google's sign-in branding guidelines ask (white button, the G, the
/// words), with Amica's rounding and press feedback.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final enabled = onPressed != null && !isBusy;
    return PressableScale(
      enabled: enabled,
      scale: 0.97,
      child: Opacity(
        opacity: enabled || isBusy ? 1 : 0.5,
        child: Material(
          color: Colors.white,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF4285F4),
                      ),
                    )
                  else
                    const GoogleLogo(size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Google's button text is dark grey on white in both
                      // light and dark mode.
                      style: const TextStyle(
                        color: Color(0xFF1F1F1F),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ── or ──
class OrDivider extends StatelessWidget {
  const OrDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Row(
      children: [
        Expanded(child: Divider(color: c.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: c.plum45),
          ),
        ),
        Expanded(child: Divider(color: c.line)),
      ],
    );
  }
}

/// An error that slides open (and closed) smoothly instead of jumping the
/// form around.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return AnimatedSize(
      duration: AmicaMotion.medium,
      curve: AmicaMotion.enter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: c.blush,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 17,
                      color: c.terracottaDeep,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        message!,
                        style: TextStyle(
                          color: c.terracottaDeep,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Eye button that shows / hides a password.
class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    required this.obscured,
    required this.onToggle,
    required this.showLabel,
    required this.hideLabel,
    super.key,
  });

  final bool obscured;
  final VoidCallback onToggle;
  final String showLabel;
  final String hideLabel;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? showLabel : hideLabel,
      color: Theme.of(context).amica.plum45,
      onPressed: onToggle,
      icon: AnimatedSwitcher(
        duration: AmicaMotion.quick,
        child: Icon(
          obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          key: ValueKey(obscured),
          size: 20,
        ),
      ),
    );
  }
}
