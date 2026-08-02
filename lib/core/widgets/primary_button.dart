import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Amica's signature gradient action button with a soft neon glow.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// When true, uses the safety-rose SOS gradient instead of the brand
  /// violet-to-cyan gradient. Reserved for destructive/emergency actions.
  final bool isDanger;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final gradient =
        isDanger ? AppColors.sosGradient : AppColors.primaryButtonGradient;
    final glowColor = isDanger ? AppColors.alert : AppColors.primary;

    return Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
          boxShadow: _enabled
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 16,
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
