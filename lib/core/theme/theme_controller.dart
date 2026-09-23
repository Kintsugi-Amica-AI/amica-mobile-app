import 'package:flutter/material.dart';

/// Drives day / night / follow-the-system for the whole app.
///
/// Night mode is not a cosmetic preference here — it is the "discreet mode"
/// switch on the profile screen. A bright ivory screen on a dark bus
/// announces that you are using a safety app, so this is a safety control
/// and lives one tap from the surface, not buried in settings.
///
/// Deliberately a plain [ValueNotifier] rather than a state-management
/// dependency: the app has no provider stack and this does not justify
/// introducing one.
class AmicaThemeController extends ValueNotifier<ThemeMode> {
  AmicaThemeController([super.mode = ThemeMode.system]);

  static final AmicaThemeController instance = AmicaThemeController();

  bool get isDiscreet => value == ThemeMode.dark;

  void setDiscreet(bool on) {
    value = on ? ThemeMode.dark : ThemeMode.light;
  }

  void followSystem() => value = ThemeMode.system;

  /// Resolves what the user will actually see right now, taking
  /// [ThemeMode.system] into account.
  bool isDiscreetIn(BuildContext context) {
    if (value == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return value == ThemeMode.dark;
  }
}
