import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Shared visual pieces for the two journey screens (start + live timer).

/// Rounded Material icon for a journey type.
IconData journeyTypeIcon(String type) => switch (type) {
      'walk' => Icons.directions_walk_rounded,
      'taxi' => Icons.local_taxi_rounded,
      'bus' => Icons.directions_bus_rounded,
      'train' => Icons.train_rounded,
      _ => Icons.commute_rounded,
    };

/// The frosted bottom sheet that floats over the journey map.
///
/// Real backdrop blur (the map is busy behind it) with a strong fill, so
/// text keeps full contrast whatever street is underneath.
class JourneyGlassSheet extends StatelessWidget {
  const JourneyGlassSheet({
    required this.scrollController,
    required this.children,
    super.key,
  });

  final ScrollController scrollController;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    // A solid lavender-tinted surface — deliberately a different colour
    // from the white glass nav pill that floats over its lower edge, so the
    // two never blur into one another.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = Color.alphaBlend(
      c.accentSoft.withValues(alpha: isDark ? 0.7 : 0.8),
      c.card,
    );
    const radius = BorderRadius.vertical(top: Radius.circular(30));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: radius,
        // Uniform (a top-only border can't have rounded corners); only the
        // top edge is ever on screen anyway.
        border: Border.all(color: c.glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  gradient: c.accentGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A round icon badge filled with the brand gradient (or a soft tint).
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    required this.icon,
    super.key,
    this.size = 42,
    this.soft = false,
  });

  final IconData icon;
  final double size;

  /// Soft: lavender tint with accent ink, instead of the full gradient.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: soft ? c.accentSoft : null,
        gradient: soft ? null : c.accentGradient,
        boxShadow: soft ? null : c.accentGlow,
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: soft ? c.accentInk : AppColors.onAccent,
      ),
    );
  }
}

/// Small tinted pill with an icon — distance, time, etc.
class InfoPill extends StatelessWidget {
  const InfoPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.accentInk),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: c.accentInk,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable journey-type chip: icon over label, gradient when chosen.
class JourneyTypeChip extends StatelessWidget {
  const JourneyTypeChip({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String type;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final fg = selected ? AppColors.onAccent : c.plum70;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? c.accentGradient : null,
            color: selected ? null : c.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.transparent : c.line,
            ),
            boxShadow: selected ? c.accentGlow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(journeyTypeIcon(type), size: 22, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
