import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'glass_card.dart';

/// Small shared pieces of the Warm Dawn vocabulary, one-to-one with the
/// design system sheet. Kept together because each is a handful of lines
/// and screens almost always need several at once.

/// What a [StatusPill] is reporting.
enum PillTone { sage, gold, blush, quiet }

/// A short status word on a tinted, rounded ground — "Live", "Active",
/// "3 of 4 done". Never interactive; if it can be tapped it is a button.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    super.key,
    this.tone = PillTone.quiet,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    final (Color bg, Color fg) = switch (tone) {
      PillTone.sage => (c.sageSoft, c.sageInk),
      PillTone.gold => (c.goldSoft, c.gold),
      PillTone.blush => (c.blush, c.terracottaDeep),
      PillTone.quiet => (c.shell, c.plum70),
    };

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
            ),
          ),
        ],
      ),
    );
  }
}

/// The uppercase eyebrow that labels a group of rows. Deliberately small
/// and muted — it orients, it does not compete.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
    if (trailing == null) return label;
    return Row(
      children: [label, const Spacer(), trailing!],
    );
  }
}

/// A square-ish feature tile for the home grid: icon in a tinted rounded
/// square, then a short label. Replaces the old glass card with a glowing
/// circular icon.
class AmicaTile extends StatelessWidget {
  const AmicaTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.tint,
    super.key,
    this.iconColor,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Background of the icon chip.
  final Color tint;

  /// Ink of the icon itself. Defaults to plum for legibility.
  final Color? iconColor;

  /// Optional short status word shown under the label.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return AmicaCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(11, 13, 11, 13),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? c.plum),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: -0.06,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 3),
            Text(
              badge!,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: c.plum45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline. One place to change it.
class AmicaDivider extends StatelessWidget {
  const AmicaDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: Theme.of(context).amica.lineSoft,
    );
  }
}

/// A tappable settings/list row: icon chip, title, optional subtitle,
/// optional trailing widget (defaults to a chevron).
class AmicaListRow extends StatelessWidget {
  const AmicaListRow({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.iconTint,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconTint;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconTint ?? c.shell,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: iconColor ?? c.plum70),
                ),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.plum45,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ] else if (showChevron && onTap != null) ...[
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, size: 20, color: c.plum45),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular initial, used for guardians in the circle.
class AmicaAvatar extends StatelessWidget {
  const AmicaAvatar({
    required this.initial,
    super.key,
    this.size = 40,
    this.background,
    this.foreground,
    this.ringColor,
  });

  final String initial;
  final double size;
  final Color? background;
  final Color? foreground;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? c.shell,
        shape: BoxShape.circle,
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: 2),
      ),
      child: Text(
        initial.isEmpty ? '?' : initial.characters.first.toUpperCase(),
        style: TextStyle(
          color: foreground ?? c.plum70,
          fontSize: size * 0.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shown where a list would otherwise be blank. Always says what the thing
/// is for and offers the action that fills it — an empty screen with only
/// "No contacts" tells a user nothing about what to do next.
class AmicaEmptyState extends StatelessWidget {
  const AmicaEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: c.shell,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 26, color: c.plum45),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
