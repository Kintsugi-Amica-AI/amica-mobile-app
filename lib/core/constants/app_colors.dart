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
  // A cool pearl white with a breath of lavender — replaces the warm
  // cream/ivory ground, which read as beige next to the pastels.
  static const Color ivory = Color(0xFFFAF7FF); // app ground
  static const Color shell = Color(0xFFF2EEFA); // recessed surface
  static const Color card = Color(0xFFFFFFFF); // raised surface

  static const Color plum = Color(0xFF2B1B3A); // primary text · 15.2:1
  static const Color plum70 = Color(0xFF5E4C6E); // secondary text · 7.3:1
  // Muted text, darkened so it still clears 4.5:1 on glass over the
  // strongest pastel wash (5.3:1 on lavender glass).
  static const Color plum45 = Color(0xFF665577);
  static const Color line = Color(0xFFE9E2F3); // hairline
  static const Color lineSoft = Color(0xFFF0EBF7); // card border

  /// Brand gradient — lavender → orchid. White text clears 4.6:1 on both
  /// ends. Used for primary actions, active nav, selected states.
  static const Color accent = Color(0xFF7C4DEB);
  static const Color accentEnd = Color(0xFFB84A9C);
  static const Color accentInk = Color(0xFF6D3FC9); // text/icons · 6.5:1
  static const Color accentSoft = Color(0xFFF0E9FF); // tinted chip ground

  /// Emergency rose. A FILL — white on it is 4.6:1. For text/icons on light
  /// grounds use [terracottaDeep] (6.4:1 on white).
  static const Color terracotta = Color(0xFFD93360);
  static const Color terracottaDeep = Color(0xFFA82246); // 5.5:1 on glass
  static const Color blush = Color(0xFFFDE4EC);

  static const Color sage = Color(0xFF2F6A4D); // success · 5.0:1 on glass
  static const Color sageInk = Color(0xFF255A40);
  static const Color sageSoft = Color(0xFFE2F3E9);

  static const Color gold = Color(0xFF7A4F0C); // warning · 5.6:1 on glass
  static const Color goldSoft = Color(0xFFFFF0DD); // peach

  static const Color sky = Color(0xFFE3F0FD);

  /// Orchid — a fourth calm tint for tiles (fake call), in place of the
  /// cream/amber one. Ink is 5.4:1 on its tint, 5.5:1 on glass.
  static const Color orchidSoft = Color(0xFFF7E6FB);
  static const Color orchidInk = Color(0xFF8E3A9E);
  static const Color skyInk = Color(0xFF2B6199); // 5.0:1 on glass

  // Ground washes — saturated enough that frosted glass over them visibly
  // picks up their colour (a pale ground makes glass look like plain white).
  static const Color glowRose = Color(0xFFFFB3D1);
  static const Color glowLavender = Color(0xFFC4B2FF);
  // (Named "peach" for history; now a soft orchid — the peach wash is what
  // gave the lower half of every screen its creamy cast.)
  static const Color glowPeach = Color(0xFFEBC2F5);
  static const Color glowSky = Color(0xFFB5DCFF);

  // Glass — 60% white over the washes. Every text token above clears 4.5:1
  // on it, measured over the strongest (lavender) wash at full strength.
  static const Color glassFill = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0xF2FFFFFF);
  static const Color glassHighlight = Color(0x73FFFFFF);

  // ── Dark ─────────────────────────────────────────────────────────────
  // Deep aubergine night. Glows are kept very faint: a bright screen on a
  // bus at night announces that you are using a safety app.
  static const Color nIvory = Color(0xFF0E0A17); // midnight plum
  static const Color nShell = Color(0xFF1A1426);
  static const Color nCard = Color(0xFF1E1730);

  static const Color nPlum = Color(0xFFF5EEF8); // 16.6:1
  static const Color nPlum70 = Color(0xFFC7B8D2); // 9.0:1
  static const Color nPlum45 = Color(0xFFA898B8); // 5.0:1 on glass
  static const Color nLine = Color(0xFF2E2540);
  static const Color nLineSoft = Color(0xFF251D35);

  static const Color nAccent = Color(0xFF7C4DEB);
  static const Color nAccentEnd = Color(0xFFB84A9C);
  static const Color nAccentInk = Color(0xFFC3AEFF); // 8.7:1
  static const Color nAccentSoft = Color(0xFF2F2358);

  static const Color nTerracotta = Color(0xFFD93360);
  static const Color nTerracottaDeep = Color(0xFFFF8FA8); // text · 7.1:1
  static const Color nBlush = Color(0xFF4A1830);

  static const Color nSage = Color(0xFF7CC39B);
  static const Color nSageInk = Color(0xFFA5DDBC);
  static const Color nSageSoft = Color(0xFF173527);

  static const Color nGold = Color(0xFFE6B566);
  static const Color nGoldSoft = Color(0xFF3A2A14);

  static const Color nSky = Color(0xFF172E4A);
  static const Color nOrchidSoft = Color(0xFF3F2150);
  static const Color nOrchidInk = Color(0xFFE3A6F0); // 7.3:1
  static const Color nSkyInk = Color(0xFF9CC7F2);

  // Deep jewel washes: enough colour for the glass to read, still dark and
  // low-glare.
  static const Color nGlowRose = Color(0xFF6B2257);
  static const Color nGlowLavender = Color(0xFF43308F);
  static const Color nGlowPeach = Color(0xFF5A2A6E); // orchid
  static const Color nGlowSky = Color(0xFF1D3D6E);

  // Smoked glass: 62% midnight over the jewel washes; every text token
  // clears 4.5:1 on it over the strongest wash.
  static const Color nGlassFill = Color(0x9E1A1426);
  static const Color nGlassBorder = Color(0x40FFFFFF);
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
    required this.orchidSoft,
    required this.orchidInk,
    required this.glowRose,
    required this.glowLavender,
    required this.glowPeach,
    required this.glowSky,
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
  final Color orchidSoft;
  final Color orchidInk;
  final Color glowRose;
  final Color glowLavender;
  final Color glowPeach;
  final Color glowSky;

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
  /// In dark mode this becomes a soft luminous halo — the one place the
  /// night theme glows, so primary actions stand out on the midnight ground.
  List<BoxShadow> get accentGlow => shadow.isEmpty
      ? [
          BoxShadow(
            color: accentEnd.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ]
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
    orchidSoft: AppColors.orchidSoft,
    orchidInk: AppColors.orchidInk,
    glowRose: AppColors.glowRose,
    glowLavender: AppColors.glowLavender,
    glowPeach: AppColors.glowPeach,
    glowSky: AppColors.glowSky,
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
    orchidSoft: AppColors.nOrchidSoft,
    orchidInk: AppColors.nOrchidInk,
    glowRose: AppColors.nGlowRose,
    glowLavender: AppColors.nGlowLavender,
    glowPeach: AppColors.nGlowPeach,
    glowSky: AppColors.nGlowSky,
    glassFill: AppColors.nGlassFill,
    glassBorder: AppColors.nGlassBorder,
    glassHighlight: AppColors.nGlassHighlight,
    shadow: [],
    // A deep rose glow under the SOS core rather than a black smudge.
    lift: [
      BoxShadow(
        color: Color(0x66D93360),
        blurRadius: 40,
        offset: Offset(0, 14),
      ),
      BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
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
    Color? orchidSoft,
    Color? orchidInk,
    Color? glowRose,
    Color? glowLavender,
    Color? glowPeach,
    Color? glowSky,
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
      orchidSoft: orchidSoft ?? this.orchidSoft,
      orchidInk: orchidInk ?? this.orchidInk,
      glowRose: glowRose ?? this.glowRose,
      glowLavender: glowLavender ?? this.glowLavender,
      glowPeach: glowPeach ?? this.glowPeach,
      glowSky: glowSky ?? this.glowSky,
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
      orchidSoft: l(orchidSoft, other.orchidSoft),
      orchidInk: l(orchidInk, other.orchidInk),
      glowRose: l(glowRose, other.glowRose),
      glowLavender: l(glowLavender, other.glowLavender),
      glowPeach: l(glowPeach, other.glowPeach),
      glowSky: l(glowSky, other.glowSky),
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
