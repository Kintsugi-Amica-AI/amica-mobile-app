import 'package:flutter/material.dart';

/// Amica's "Blossom" colour system.
///
/// Soft, pastel and calm — rose, lavender and peach over an airy
/// pink-white ground — in place of the earlier flat "Warm Dawn" ivory.
/// The token *names* are unchanged (`ivory`, `plum`, `terracotta` …) so
/// every screen picks the new look up without being rewritten; read the
/// names as roles, not hues:
///
/// | token          | role                                   |
/// |----------------|----------------------------------------|
/// | `ivory`        | app ground (base under the gradient)   |
/// | `shell`        | recessed surface, quiet fills          |
/// | `card`         | raised surface                         |
/// | `plum*`        | text, three strengths                  |
/// | `accent*`      | brand: lavender → orchid, primary CTAs |
/// | `terracotta*`  | EMERGENCY ONLY (rose-red)              |
/// | `sage*`        | safe / success                         |
/// | `gold*`        | caution / warning (peach ground)       |
/// | `sky*`         | calm informational tint                |
///
/// Two rules carry over from Warm Dawn:
///
/// 1. **Rose-red only ever means emergency.** The brand gradient is
///    lavender → orchid precisely so that it can never be mistaken for the
///    SOS colour.
/// 2. **Everything is measured.** Each text colour below carries its
///    contrast ratio against the surface it is used on. Nothing ships under
///    4.5:1 — this app gets read one-handed, at night, by someone frightened.
///
/// Dark mode is the same token names with swapped values, so widgets never
/// branch on brightness — they read [AmicaColors] off the theme.
class AppColors {
  const AppColors._();

  // ── Light ────────────────────────────────────────────────────────────
  static const Color ivory = Color(0xFFFFF8FB); // app ground
  static const Color shell = Color(0xFFF7EEF6); // recessed surface
  static const Color card = Color(0xFFFFFFFF); // raised surface

  static const Color plum = Color(0xFF2B1B3A); // primary text · 15.2:1
  static const Color plum70 = Color(0xFF5E4C6E); // secondary text · 7.3:1
  static const Color plum45 = Color(0xFF756385); // muted text · 4.8:1 on shell
  static const Color line = Color(0xFFEEE2EE); // hairline
  static const Color lineSoft = Color(0xFFF4EBF3); // card border

  /// Brand gradient — lavender → orchid. White text clears 4.6:1 on both
  /// ends. Used for primary actions, active nav, selected states.
  static const Color accent = Color(0xFF7C4DEB);
  static const Color accentEnd = Color(0xFFB84A9C);
  static const Color accentInk = Color(0xFF6D3FC9); // text/icons · 6.5:1
  static const Color accentSoft = Color(0xFFF0E9FF); // tinted chip ground

  /// Emergency rose. A FILL — white on it is 4.6:1. For text/icons on light
  /// grounds use [terracottaDeep] (6.4:1 on white).
  static const Color terracotta = Color(0xFFD93360);
  static const Color terracottaDeep = Color(0xFFB3264B);
  static const Color blush = Color(0xFFFDE4EC);

  static const Color sage = Color(0xFF3A7A5A); // success · 5.1:1
  static const Color sageInk = Color(0xFF2C5F45);
  static const Color sageSoft = Color(0xFFE2F3E9);

  static const Color gold = Color(0xFF8A5A10); // warning · 5.3:1
  static const Color goldSoft = Color(0xFFFFF0DD); // peach

  static const Color sky = Color(0xFFE3F0FD);
  static const Color skyInk = Color(0xFF2D6AA3); // 4.9:1 on sky

  // Ground glows — the soft pastel washes behind every screen.
  static const Color glowRose = Color(0xFFFFD9E8);
  static const Color glowLavender = Color(0xFFE6DCFF);
  static const Color glowPeach = Color(0xFFFFE6D8);

  // Glass — frosted white over the pastel ground. Fill is 72% white, so
  // muted text still clears 4.8:1 over the strongest rose wash.
  static const Color glassFill = Color(0xB8FFFFFF);
  static const Color glassBorder = Color(0xE6FFFFFF);
  static const Color glassHighlight = Color(0x99FFFFFF);

  // ── Dark ─────────────────────────────────────────────────────────────
  // Deep aubergine night. Glows are kept very faint: a bright screen on a
  // bus at night announces that you are using a safety app.
  static const Color nIvory = Color(0xFF140F1C);
  static const Color nShell = Color(0xFF1E1729);
  static const Color nCard = Color(0xFF211A2D);

  static const Color nPlum = Color(0xFFF5EEF8); // 16.6:1
  static const Color nPlum70 = Color(0xFFC7B8D2); // 9.0:1
  static const Color nPlum45 = Color(0xFF9D8DAB); // 5.5:1
  static const Color nLine = Color(0xFF33283F);
  static const Color nLineSoft = Color(0xFF2B2236);

  static const Color nAccent = Color(0xFF7C4DEB);
  static const Color nAccentEnd = Color(0xFFB84A9C);
  static const Color nAccentInk = Color(0xFFC3AEFF); // 8.7:1
  static const Color nAccentSoft = Color(0xFF2A2140);

  static const Color nTerracotta = Color(0xFFD93360);
  static const Color nTerracottaDeep = Color(0xFFFF8FA8); // text · 7.1:1
  static const Color nBlush = Color(0xFF3A1C2B);

  static const Color nSage = Color(0xFF7CC39B);
  static const Color nSageInk = Color(0xFFA5DDBC);
  static const Color nSageSoft = Color(0xFF17291F);

  static const Color nGold = Color(0xFFE6B566);
  static const Color nGoldSoft = Color(0xFF33261A);

  static const Color nSky = Color(0xFF1A2638);
  static const Color nSkyInk = Color(0xFF9CC7F2);

  static const Color nGlowRose = Color(0xFF3A1830);
  static const Color nGlowLavender = Color(0xFF261C44);
  static const Color nGlowPeach = Color(0xFF2A1A22);

  static const Color nGlassFill = Color(0x9E2A2238);
  static const Color nGlassBorder = Color(0x1FFFFFFF);
  static const Color nGlassHighlight = Color(0x14FFFFFF);

  // ── Ink used ON coloured fills ───────────────────────────────────────
  static const Color onTerracotta = Color(0xFFFFFFFF);
  static const Color onSage = Color(0xFFF4F8F3);
  static const Color onAccent = Color(0xFFFFFFFF);
}

/// The Blossom tokens, resolved for the current brightness.
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
    required this.accent,
    required this.accentEnd,
    required this.accentInk,
    required this.accentSoft,
    required this.terracotta,
    required this.terracottaDeep,
    required this.blush,
    required this.sage,
    required this.sageInk,
    required this.sageSoft,
    required this.gold,
    required this.goldSoft,
    required this.sky,
    required this.skyInk,
    required this.glowRose,
    required this.glowLavender,
    required this.glowPeach,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
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
  final Color accent;
  final Color accentEnd;
  final Color accentInk;
  final Color accentSoft;
  final Color terracotta;
  final Color terracottaDeep;
  final Color blush;
  final Color sage;
  final Color sageInk;
  final Color sageSoft;
  final Color gold;
  final Color goldSoft;
  final Color sky;
  final Color skyInk;
  final Color glowRose;
  final Color glowLavender;
  final Color glowPeach;

  /// Translucent frosted-glass fill, its bright rim, and the sheen laid
  /// across the top-left of a glass surface.
  final Color glassFill;
  final Color glassBorder;
  final Color glassHighlight;

  /// Resting elevation for cards and tiles — a soft, tinted, diffuse shadow
  /// in light mode. Empty in dark mode: shadows read as grey smudges on a
  /// dark ground, so dark separates with borders.
  final List<BoxShadow> shadow;

  /// Reserved for the one genuinely raised element on a screen: the SOS core.
  final List<BoxShadow> lift;

  /// The brand gradient for primary actions and selected states.
  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accentEnd],
      );

  /// The emergency gradient — only ever on SOS surfaces.
  LinearGradient get sosGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(terracotta, Colors.white, 0.12)!,
          Color.lerp(terracotta, Colors.black, 0.08)!,
        ],
      );

  /// The frosted surface: translucent fill with a soft sheen from the
  /// top-left, as used by [AmicaCard] and [AmicaGlass].
  LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(glassHighlight, glassFill),
          glassFill,
        ],
      );

  /// Soft coloured glow under an accent-filled control.
  List<BoxShadow> get accentGlow => shadow.isEmpty
      ? const []
      : [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ];

  static const AmicaColors day = AmicaColors(
    ivory: AppColors.ivory,
    shell: AppColors.shell,
    card: AppColors.card,
    plum: AppColors.plum,
    plum70: AppColors.plum70,
    plum45: AppColors.plum45,
    line: AppColors.line,
    lineSoft: AppColors.lineSoft,
    accent: AppColors.accent,
    accentEnd: AppColors.accentEnd,
    accentInk: AppColors.accentInk,
    accentSoft: AppColors.accentSoft,
    terracotta: AppColors.terracotta,
    terracottaDeep: AppColors.terracottaDeep,
    blush: AppColors.blush,
    sage: AppColors.sage,
    sageInk: AppColors.sageInk,
    sageSoft: AppColors.sageSoft,
    gold: AppColors.gold,
    goldSoft: AppColors.goldSoft,
    sky: AppColors.sky,
    skyInk: AppColors.skyInk,
    glowRose: AppColors.glowRose,
    glowLavender: AppColors.glowLavender,
    glowPeach: AppColors.glowPeach,
    glassFill: AppColors.glassFill,
    glassBorder: AppColors.glassBorder,
    glassHighlight: AppColors.glassHighlight,
    shadow: [
      BoxShadow(color: Color(0x0A6B3F8F), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x146B3F8F),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
    lift: [
      BoxShadow(
        color: Color(0x40D93360),
        blurRadius: 36,
        offset: Offset(0, 16),
      ),
      BoxShadow(color: Color(0x1AD93360), blurRadius: 6, offset: Offset(0, 2)),
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
    accent: AppColors.nAccent,
    accentEnd: AppColors.nAccentEnd,
    accentInk: AppColors.nAccentInk,
    accentSoft: AppColors.nAccentSoft,
    terracotta: AppColors.nTerracotta,
    terracottaDeep: AppColors.nTerracottaDeep,
    blush: AppColors.nBlush,
    sage: AppColors.nSage,
    sageInk: AppColors.nSageInk,
    sageSoft: AppColors.nSageSoft,
    gold: AppColors.nGold,
    goldSoft: AppColors.nGoldSoft,
    sky: AppColors.nSky,
    skyInk: AppColors.nSkyInk,
    glowRose: AppColors.nGlowRose,
    glowLavender: AppColors.nGlowLavender,
    glowPeach: AppColors.nGlowPeach,
    glassFill: AppColors.nGlassFill,
    glassBorder: AppColors.nGlassBorder,
    glassHighlight: AppColors.nGlassHighlight,
    shadow: [],
    lift: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 36,
        offset: Offset(0, 16),
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
    Color? accent,
    Color? accentEnd,
    Color? accentInk,
    Color? accentSoft,
    Color? terracotta,
    Color? terracottaDeep,
    Color? blush,
    Color? sage,
    Color? sageInk,
    Color? sageSoft,
    Color? gold,
    Color? goldSoft,
    Color? sky,
    Color? skyInk,
    Color? glowRose,
    Color? glowLavender,
    Color? glowPeach,
    Color? glassFill,
    Color? glassBorder,
    Color? glassHighlight,
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
      accent: accent ?? this.accent,
      accentEnd: accentEnd ?? this.accentEnd,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      terracotta: terracotta ?? this.terracotta,
      terracottaDeep: terracottaDeep ?? this.terracottaDeep,
      blush: blush ?? this.blush,
      sage: sage ?? this.sage,
      sageInk: sageInk ?? this.sageInk,
      sageSoft: sageSoft ?? this.sageSoft,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      sky: sky ?? this.sky,
      skyInk: skyInk ?? this.skyInk,
      glowRose: glowRose ?? this.glowRose,
      glowLavender: glowLavender ?? this.glowLavender,
      glowPeach: glowPeach ?? this.glowPeach,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      shadow: shadow ?? this.shadow,
      lift: lift ?? this.lift,
    );
  }

  @override
  AmicaColors lerp(covariant AmicaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AmicaColors(
      ivory: l(ivory, other.ivory),
      shell: l(shell, other.shell),
      card: l(card, other.card),
      plum: l(plum, other.plum),
      plum70: l(plum70, other.plum70),
      plum45: l(plum45, other.plum45),
      line: l(line, other.line),
      lineSoft: l(lineSoft, other.lineSoft),
      accent: l(accent, other.accent),
      accentEnd: l(accentEnd, other.accentEnd),
      accentInk: l(accentInk, other.accentInk),
      accentSoft: l(accentSoft, other.accentSoft),
      terracotta: l(terracotta, other.terracotta),
      terracottaDeep: l(terracottaDeep, other.terracottaDeep),
      blush: l(blush, other.blush),
      sage: l(sage, other.sage),
      sageInk: l(sageInk, other.sageInk),
      sageSoft: l(sageSoft, other.sageSoft),
      gold: l(gold, other.gold),
      goldSoft: l(goldSoft, other.goldSoft),
      sky: l(sky, other.sky),
      skyInk: l(skyInk, other.skyInk),
      glowRose: l(glowRose, other.glowRose),
      glowLavender: l(glowLavender, other.glowLavender),
      glowPeach: l(glowPeach, other.glowPeach),
      glassFill: l(glassFill, other.glassFill),
      glassBorder: l(glassBorder, other.glassBorder),
      glassHighlight: l(glassHighlight, other.glassHighlight),
      shadow: BoxShadow.lerpList(shadow, other.shadow, t) ?? shadow,
      lift: BoxShadow.lerpList(lift, other.lift, t) ?? lift,
    );
  }
}

/// `Theme.of(context).amica` — shorthand for the token set.
extension AmicaColorsX on ThemeData {
  AmicaColors get amica => extension<AmicaColors>() ?? AmicaColors.day;
}
