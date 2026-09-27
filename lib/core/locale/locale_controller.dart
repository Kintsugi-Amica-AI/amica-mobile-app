import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the app's display language (English, Sinhala, Tamil).
///
/// A plain [ValueNotifier], matching [AmicaThemeController]: the app has no
/// provider stack and a second small piece of rarely-changing global state
/// does not justify adding one.
class AmicaLocaleController extends ValueNotifier<Locale?> {
  AmicaLocaleController([super.locale]);

  /// The single instance the whole app reads and writes through, same
  /// pattern as [AmicaThemeController.instance].
  static final AmicaLocaleController instance = AmicaLocaleController();

  static const _prefsKey = 'amica_locale_code';

  /// Languages Amica ships with, in the order shown on the language picker.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// Each language's own name for itself, for the picker label — not the
  /// current UI language's translation of it, so a Sinhala speaker who
  /// opened the picker by accident can still find their way back.
  static const Map<String, String> nativeNames = {
    'en': 'English',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
  };

  /// Reads the language the user picked last time, if any.
  ///
  /// Call once, before [runApp]. With nothing saved yet, [value] stays
  /// null and [MaterialApp.localeResolutionCallback] falls back to the
  /// device's own language (or English if Amica does not ship that one).
  static Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null &&
          supportedLocales.any((locale) => locale.languageCode == code)) {
        instance.value = Locale(code);
      }
    } catch (_) {
      // No storage available yet (e.g. first run in a restricted
      // environment); the app still works, just without a remembered
      // language until the next successful save.
    }
  }

  /// Switches the app's language immediately and remembers the choice.
  ///
  /// Pass `null` to go back to following the device's language.
  Future<void> setLocale(Locale? locale) async {
    value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (_) {
      // Best effort: the UI has already switched for this session even if
      // the choice could not be persisted.
    }
  }
}
