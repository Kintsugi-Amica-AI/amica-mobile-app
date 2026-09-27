import 'package:flutter/foundation.dart';

/// One tag for every on-device vision step, so the scan pipeline can be
/// followed with `adb logcat -s flutter | findstr AmicaVision` (Windows) or
/// `| grep AmicaVision`. Printed in debug and profile builds only.
void visionLog(String message) {
  if (kReleaseMode) return;
  debugPrint('AmicaVision: $message');
}
