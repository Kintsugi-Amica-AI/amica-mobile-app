import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives Light / Dark / follow-the-system for the whole app.
///
/// Light is the default look. Dark doubles as "discreet mode": a bright
/// screen on a dark bus announces that you are using a safety app, so the
/// quick moon toggle on Home stays one tap from the surface. The full
/// three-way choice (Light · Dark · System) lives on the Profile tab.
///
/// The choice is remembered across launches, same pattern as
/// [AmicaLocaleController]. A plain [ValueNotifier] rather than a
/// state-management dependency: the app has no provider stack and this
/// does not justify introducing one.
class AmicaThemeController extends ValueNotifier<ThemeMode> {
  AmicaThemeController([super.mode = ThemeMode.light]);

  static final AmicaThemeController instance = AmicaThemeController();

  static const _prefsKey = 'amica_theme_mode';

  /// Reads the appearance the user picked last time. Call once before
  /// [runApp]; with nothing saved the app stays on [ThemeMode.light].
  static Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      for (final mode in ThemeMode.values) {
        if (mode.name == saved) {
          instance.value = mode;
          return;
        }
      }
    } catch (_) {
      // No storage yet; keep the default and carry on.
    }
  }

  /// Switches appearance immediately and remembers the choice.
  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Best effort: the UI has already switched for this session.
    }
  }

  bool get isDiscreet => value == ThemeMode.dark;

  void setDiscreet(bool on) => setMode(on ? ThemeMode.dark : ThemeMode.light);

  void followSystem() => setMode(ThemeMode.system);

  /// Resolves what the user will actually see right now, taking
  /// [ThemeMode.system] into account.
  bool isDiscreetIn(BuildContext context) {
    if (value == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return value == ThemeMode.dark;
  }
}
