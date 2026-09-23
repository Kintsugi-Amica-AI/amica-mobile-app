import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Amica's "Warm Dawn" theme.
///
/// Two themes, one token set: [light] is the daytime app, [dark] is the
/// discreet night mode. Neither is a restyle of the other — they are the
/// same [AmicaColors] structure with swapped values, so no widget in the
/// app needs to branch on brightness.
///
/// Type is Bricolage Grotesque for display sizes and Public Sans for
/// everything else. Both are bundled under `assets/fonts/` rather than
/// fetched at runtime: an app someone opens when they are frightened has
/// to render correctly with no network.
class AppTheme {
  const AppTheme._();

  static const String displayFont = 'BricolageGrotesque';
  static const String bodyFont = 'PublicSans';

  static ThemeData get light => _build(AmicaColors.day, Brightness.light);
  static ThemeData get dark => _build(AmicaColors.night, Brightness.dark);

  /// Status-bar / nav-bar icon styling per mode. Applied at the app root so
  /// the system chrome matches the surface underneath it.
  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? AppColors.nCard : AppColors.card,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  static ThemeData _build(AmicaColors c, Brightness brightness) {
    final textTheme = _textTheme(c);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.plum,
      onPrimary: c.ivory,
      secondary: c.sage,
      onSecondary: AppColors.onSage,
      error: c.terracotta,
      onError: AppColors.onTerracotta,
      surface: c.card,
      onSurface: c.plum,
      surfaceContainerHighest: c.shell,
      outline: c.line,
      outlineVariant: c.lineSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [c],
      scaffoldBackgroundColor: c.ivory,
      canvasColor: c.ivory,
      fontFamily: bodyFont,
      textTheme: textTheme,
      // Warm Dawn has no ripple-and-glow. Touch feedback is a quiet tint.
      splashFactory: InkSparkle.splashFactory,
      splashColor: c.plum.withValues(alpha: 0.05),
      highlightColor: c.plum.withValues(alpha: 0.03),
      dividerColor: c.lineSoft,
      dividerTheme: DividerThemeData(
        color: c.lineSoft,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: c.ivory,
        foregroundColor: c.plum,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayFor(brightness),
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: c.plum, size: 22),
      ),

      iconTheme: IconThemeData(color: c.plum70, size: 22),

      // 54px controls — comfortably above the 44px minimum, and reachable
      // with one thumb while walking.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.plum,
          foregroundColor: c.ivory,
          disabledBackgroundColor: c.shell,
          disabledForegroundColor: c.plum45,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.shell,
          foregroundColor: c.plum,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: c.line),
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.terracottaDeep,
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        labelStyle: TextStyle(color: c.plum70, fontSize: 14),
        floatingLabelStyle: TextStyle(color: c.plum, fontSize: 13),
        hintStyle: TextStyle(color: c.plum45, fontSize: 15),
        helperStyle: TextStyle(color: c.plum45, fontSize: 12),
        errorStyle: TextStyle(color: c.terracottaDeep, fontSize: 12),
        prefixIconColor: c.plum45,
        suffixIconColor: c.plum45,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: _fieldBorder(c.line),
        enabledBorder: _fieldBorder(c.line),
        focusedBorder: _fieldBorder(c.plum, width: 1.6),
        errorBorder: _fieldBorder(c.terracotta, width: 1.4),
        focusedErrorBorder: _fieldBorder(c.terracotta, width: 1.6),
      ),

      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.lineSoft),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.plum45,
        textColor: c.plum,
        minVerticalPadding: 10,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.card,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.sage : c.line,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.sage : c.line,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.shell,
        labelStyle: TextStyle(
          fontFamily: bodyFont,
          color: c.plum70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        shape: const StadiumBorder(),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.plum,
        contentTextStyle: TextStyle(
          fontFamily: bodyFont,
          color: c.ivory,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: c.blush,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? c.plum : c.plum45,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: bodyFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected) ? c.plum : c.plum45,
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.plum,
        linearTrackColor: c.shell,
        circularTrackColor: c.shell,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          fontFamily: bodyFont,
          color: c.plum,
          fontSize: 15,
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: c.lineSoft),
            ),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// The type ramp, one-to-one with the design system sheet.
  ///
  /// Display sizes use Bricolage Grotesque at w600 — it is a display face
  /// and thins out badly at w400. Everything from `titleMedium` down is
  /// Public Sans, which holds up at small sizes in low light.
  static TextTheme _textTheme(AmicaColors c) {
    return TextTheme(
      // display — the greeting, the one big line on a screen
      displaySmall: TextStyle(
        fontFamily: displayFont,
        color: c.plum,
        fontSize: 29,
        height: 1.14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.64,
      ),
      // h1
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        color: c.plum,
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFont,
        color: c.plum,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      // h2 — section headings, in body face
      titleLarge: TextStyle(
        color: c.plum,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.18,
      ),
      // .title
      titleMedium: TextStyle(
        color: c.plum,
        fontSize: 15.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: c.plum,
        fontSize: 13.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: c.plum,
        fontSize: 15,
        height: 1.47,
        fontWeight: FontWeight.w400,
      ),
      // .body
      bodyMedium: TextStyle(
        color: c.plum70,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      // .label
      bodySmall: TextStyle(
        color: c.plum70,
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: c.plum,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
      ),
      // .micro — the uppercase eyebrow above a group
      labelSmall: TextStyle(
        color: c.plum45,
        fontSize: 10,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}
