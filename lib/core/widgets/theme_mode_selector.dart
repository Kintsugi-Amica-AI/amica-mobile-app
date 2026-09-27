import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../theme/theme_controller.dart';

/// Light · Dark · System — a three-way pill switch for the app's
/// appearance. Reads and writes [AmicaThemeController], so the whole app
/// restyles the moment a segment is tapped, and the choice is remembered
/// on the next launch.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, this.controller});

  /// Defaults to [AmicaThemeController.instance]; injectable for tests.
  final AmicaThemeController? controller;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? AmicaThemeController.instance;
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;

    final options = <(ThemeMode, IconData, String)>[
      (ThemeMode.light, Icons.light_mode_outlined, loc.themeLight),
      (ThemeMode.dark, Icons.dark_mode_outlined, loc.themeDark),
      (ThemeMode.system, Icons.brightness_auto_outlined, loc.themeSystem),
    ];

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ctrl,
      builder: (context, mode, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.shell,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.lineSoft),
          ),
          child: Row(
            children: [
              for (final (value, icon, label) in options)
                Expanded(
                  child: _Segment(
                    icon: icon,
                    label: label,
                    selected: mode == value,
                    onTap: () => ctrl.setMode(value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected ? c.accentGradient : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? c.accentGlow : const [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
