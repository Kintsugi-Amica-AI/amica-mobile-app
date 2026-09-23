import 'package:flutter/material.dart';

import 'app.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.instance.initialize();
  await AmicaLocaleController.loadSaved();
  await AmicaThemeController.loadSaved();
  runApp(const AmicaApp());
}
