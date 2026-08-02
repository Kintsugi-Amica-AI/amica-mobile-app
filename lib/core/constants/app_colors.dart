import 'package:flutter/material.dart';

/// Amica's futuristic, women-first color system.
///
/// The palette pairs a deep-space indigo/violet base with an electric cyan
/// accent (matching the Amica/iDEALiZE brand mark) and a warm safety-rose
/// accent used for SOS, alerts, and empowerment moments.
class AppColors {
  const AppColors._();

  // Brand core
  static const Color primary = Color(0xFF8B5CF6); // electric violet
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF22D3EE); // neon cyan
  static const Color accent = Color(0xFF22D3EE);

  // Safety semantics
  static const Color alert = Color(0xFFFF3D71); // safety rose / SOS
  static const Color alertDark = Color(0xFFB3123F);
  static const Color success = Color(0xFF17E6A1);
  static const Color warning = Color(0xFFFFC24B);

  // Surfaces (dark, "deep space")
  static const Color background = Color(0xFF0A0417);
  static const Color backgroundAlt = Color(0xFF130A2A);
  static const Color surface = Color(0xFF1B1030);
  static const Color surfaceElevated = Color(0xFF241640);

  // Glass overlay tones (used with low opacity over gradients)
  static const Color glassFill = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFB2A8D6);
  static const Color textMuted = Color(0xFF7B7299);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0417),
      Color(0xFF1B0B3A),
      Color(0xFF2C0F52),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
  );

  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3D71), Color(0xFFB3123F)],
  );

  static const LinearGradient auraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF8B5CF6), Color(0xFFFF3D71)],
  );
}
