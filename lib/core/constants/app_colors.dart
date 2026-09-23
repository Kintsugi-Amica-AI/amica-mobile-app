import 'package:flutter/material.dart';

/// Amica's "Warm Dawn" colour system.
///
/// Replaces the previous deep-space violet / neon-cyan palette. Two things
/// drive every value here:
///
/// 1. **Terracotta only ever means emergency.** No other control, icon or
///    accent is allowed to use it, so the SOS affordance never has to compete
///    for attention on a busy screen.
/// 2. **Everything is measured.** Each text colour below carries its contrast
///    ratio against the surface it is used on. Nothing ships under 4.5:1 —
///    this app gets read one-handed, at night, by someone frightened.
///
/// Night mode is not a separate design. It is the same token names with
/// swapped values, so widgets never branch on brightness — they read
/// [AmicaColors] off the theme and the right value arrives.
class AppColors {
  const AppColors._();

  // ── Day ──────────────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFFDF8F4); // app background
  static const Color shell = Color(0xFFF6EDE6); // recessed surface
  static const Color card = Color(0xFFFFFFFF); // raised surface

  static const Color plum = Color(0xFF3B2230); // primary text · 13.2:1
  static const Color plum70 = Color(0xFF6B4F5E); // secondary text · 6.7:1
  static const Color plum45 = Color(0xFF7E6473); // muted text · 5.0:1
  static const Color line = Color(0xFFEBDFD6); // hairline
  static const Color lineSoft = Color(0xFFF2E8E0); // card border

  /// Terracotta is a FILL. For text or icons on ivory use [terracottaDeep] —
  /// the flat colour only reaches 4.2:1, the deep spelling reaches 6.2:1.
  static const Color terracotta = Color(0xFFC2543D);
  static const Color terracottaDeep = Color(0xFF9E3E2B);
  static const Color blush = Color(0xFFF7E2DA);

  static const Color sage = Color(0xFF4F7557); // success · 4.9:1
  static const Color sageInk = Color(0xFF3C5B43);
  static const Color sageSoft = Color(0xFFE6EEE6);

  static const Color gold = Color(0xFF8F6216); // warning · 5.0:1
  static const Color goldSoft = Color(0xFFF8EEDA);

  // ── Night / discreet ─────────────────────────────────────────────────
  // Matte throughout. No glow, no saturated fills — a bright screen on a bus
  // at night announces that you are using a safety app.
  static const Color nIvory = Color(0xFF191015);
  static const Color nShell = Color(0xFF241821);
  static const Color nCard = Color(0xFF241821);

  static const Color nPlum = Color(0xFFF4EAE3);
  static const Color nPlum70 = Color(0xFFC3ABB6);
  static const Color nPlum45 = Color(0xFF9A8290);
  static const Color nLine = Color(0xFF382933);
  static const Color nLineSoft = Color(0xFF31242D);

  static const Color nTerracotta = Color(0xFFE0705A);
  static const Color nTerracottaDeep = Color(0xFFC2543D);
  static const Color nBlush = Color(0xFF3B2129);

  static const Color nSage = Color(0xFF89B291);
  static const Color nSageInk = Color(0xFFA7C9AD);
  static const Color nSageSoft = Color(0xFF1F2C22);

  static const Color nGold = Color(0xFFD7A75C);
  static const Color nGoldSoft = Color(0xFF332619);

  // ── Ink used ON coloured fills ───────────────────────────────────────
  static const Color onTerracotta = Color(0xFFFFF6F2);
  static const Color onSage = Color(0xFFF4F8F3);
}

/// The Warm Dawn tokens, resolved for the current brightness.
///
/// Read these instead of [AppColors] directly:
/// `final c = Theme.of(context).amica;`
@immutable
class AmicaColors extends ThemeExtension<AmicaColors> {
  const AmicaColors({
    required this.ivory,
    required this.shell,
    required this.card,
    required this.plum,
    required this.plum70,
    required this.plum45,
    required this.line,
    required this.lineSoft,
    required this.terracotta,
    required this.terracottaDeep,
    required this.blush,
    required this.sage,
    required this.sageInk,
    required this.sageSoft,
    required this.gold,
    required this.goldSoft,
    required this.shadow,
    required this.lift,
  });

  final Color ivory;
  final Color shell;
  final Color card;
  final Color plum;
  final Color plum70;
  final Color plum45;
  final Color line;
  final Color lineSoft;
  final Color terracotta;
  final Color terracottaDeep;
  final Color blush;
  final Color sage;
  final Color sageInk;
  final Color sageSoft;
  final Color gold;
  final Color goldSoft;

  /// Resting elevation for cards and tiles. Empty in night mode — shadows
  /// read as grey smudges on a dark ground, so night separates with borders.
  final List<BoxShadow> shadow;

  /// Reserved for the one genuinely raised element on a screen: the SOS core.
  final List<BoxShadow> lift;

  static const AmicaColors day = AmicaColors(
    ivory: AppColors.ivory,
    shell: AppColors.shell,
    card: AppColors.card,
    plum: AppColors.plum,
    plum70: AppColors.plum70,
    plum45: AppColors.plum45,
    line: AppColors.line,
    lineSoft: AppColors.lineSoft,
    terracotta: AppColors.terracotta,
    terracottaDeep: AppColors.terracottaDeep,
    blush: AppColors.blush,
    sage: AppColors.sage,
    sageInk: AppColors.sageInk,
    sageSoft: AppColors.sageSoft,
    gold: AppColors.gold,
    goldSoft: AppColors.goldSoft,
    shadow: [
      BoxShadow(color: Color(0x0D3B2230), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0D3B2230), blurRadius: 12, offset: Offset(0, 4)),
    ],
    lift: [
      BoxShadow(color: Color(0x0F3B2230), blurRadius: 4, offset: Offset(0, 2)),
      BoxShadow(
        color: Color(0x1A3B2230),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );

  static const AmicaColors night = AmicaColors(
    ivory: AppColors.nIvory,
    shell: AppColors.nShell,
    card: AppColors.nCard,
    plum: AppColors.nPlum,
    plum70: AppColors.nPlum70,
    plum45: AppColors.nPlum45,
    line: AppColors.nLine,
    lineSoft: AppColors.nLineSoft,
    terracotta: AppColors.nTerracotta,
    terracottaDeep: AppColors.nTerracottaDeep,
    blush: AppColors.nBlush,
    sage: AppColors.nSage,
    sageInk: AppColors.nSageInk,
    sageSoft: AppColors.nSageSoft,
    gold: AppColors.nGold,
    goldSoft: AppColors.nGoldSoft,
    shadow: [],
    lift: [
      BoxShadow(
        color: Color(0x733B2230),
        blurRadius: 40,
        offset: Offset(0, 18),
      ),
    ],
  );

  @override
  AmicaColors copyWith({
    Color? ivory,
    Color? shell,
    Color? card,
    Color? plum,
    Color? plum70,
    Color? plum45,
    Color? line,
    Color? lineSoft,
    Color? terracotta,
    Color? terracottaDeep,
    Color? blush,
    Color? sage,
    Color? sageInk,
    Color? sageSoft,
    Color? gold,
    Color? goldSoft,
    List<BoxShadow>? shadow,
    List<BoxShadow>? lift,
  }) {
    return AmicaColors(
      ivory: ivory ?? this.ivory,
      shell: shell ?? this.shell,
      card: card ?? this.card,
      plum: plum ?? this.plum,
      plum70: plum70 ?? this.plum70,
      plum45: plum45 ?? this.plum45,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      terracotta: terracotta ?? this.terracotta,
      terracottaDeep: terracottaDeep ?? this.terracottaDeep,
      blush: blush ?? this.blush,
      sage: sage ?? this.sage,
      sageInk: sageInk ?? this.sageInk,
      sageSoft: sageSoft ?? this.sageSoft,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      shadow: shadow ?? this.shadow,
      lift: lift ?? this.lift,
    );
  }

  @override
  AmicaColors lerp(covariant AmicaColors? other, double t) {
    if (other == null) return this;
    return AmicaColors(
      ivory: Color.lerp(ivory, other.ivory, t)!,
      shell: Color.lerp(shell, other.shell, t)!,
      card: Color.lerp(card, other.card, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
      plum70: Color.lerp(plum70, other.plum70, t)!,
      plum45: Color.lerp(plum45, other.plum45, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineSoft: Color.lerp(lineSoft, other.lineSoft, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      terracottaDeep: Color.lerp(terracottaDeep, other.terracottaDeep, t)!,
      blush: Color.lerp(blush, other.blush, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageInk: Color.lerp(sageInk, other.sageInk, t)!,
      sageSoft: Color.lerp(sageSoft, other.sageSoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      lift: BoxShadow.lerpList(lift, other.lift, t) ?? lift,
    );
  }
}

/// `Theme.of(context).amica` — shorthand for the token set.
extension AmicaColorsX on ThemeData {
  AmicaColors get amica => extension<AmicaColors>() ?? AmicaColors.day;
}
