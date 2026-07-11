import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_routes.dart';
import '../../auth/services/user_profile_service.dart';

class FakeCallShortcutService {
  FakeCallShortcutService({
    UserProfileService userProfileService = const UserProfileService(),
  }) : _userProfileService = userProfileService;

  static const MethodChannel _channel = MethodChannel(
    'com.kintsugi.amica/emergency_actions',
  );

  final UserProfileService _userProfileService;
  bool _isNavigating = false;

  void configure({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onVolumeDownTriplePress') {
        return false;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _isNavigating) {
        return false;
      }

      final settings = await _userProfileService.getSafetySettings();
      if (settings['fakeCallVolumeShortcutEnabled'] != true) {
        return false;
      }

      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        return false;
      }

      _isNavigating = true;
      navigator.pushNamed(AppRoutes.fakeCall).whenComplete(() {
        _isNavigating = false;
      });
      return true;
    });
  }
}
