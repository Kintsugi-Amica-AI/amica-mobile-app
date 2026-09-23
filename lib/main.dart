import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'services/firebase_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars (see AppTheme.overlayFor).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await FirebaseService.instance.initialize();
  if (FirebaseService.instance.isConfigured) {
    // Circle alerts arriving while Amica is closed.
    FirebaseMessaging.onBackgroundMessage(amicaFirebaseBackgroundHandler);
  }
  await AmicaLocaleController.loadSaved();
  await AmicaThemeController.loadSaved();
  runApp(const AmicaApp());
}
