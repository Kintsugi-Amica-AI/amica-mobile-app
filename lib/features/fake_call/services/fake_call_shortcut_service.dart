import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_routes.dart';
import '../../../services/emergency_action_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../screens/fake_call_screen.dart';

class FakeCallShortcutService {
  FakeCallShortcutService({
    UserProfileService userProfileService = const UserProfileService(),
    EmergencyActionService emergencyActionService =
        const EmergencyActionService(),
  })  : _userProfileService = userProfileService,
        _emergencyActionService = emergencyActionService;

  static const MethodChannel _channel = MethodChannel(
    'com.kintsugi.amica/emergency_actions',
  );

  final UserProfileService _userProfileService;
  final EmergencyActionService _emergencyActionService;
  bool _isNavigating = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<User?>? _authSubscription;

  void configure({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _navigatorKey = navigatorKey;
    _channel.setMethodCallHandler((call) async {
      return switch (call.method) {
        'onVolumeDownTriplePress' => _handleShortcutRequest(),
        'onScheduledFakeCallDue' => _openCallScreen(),
        _ => false,
      };
    });

    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(syncShortcutMonitor());
    });
    unawaited(syncShortcutMonitor());
    unawaited(_openPendingShortcutIfNeeded());
    unawaited(_openPendingScheduledCallIfNeeded());
  }

  Future<void> syncShortcutMonitor() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _emergencyActionService.stopFakeCallShortcutMonitor();
        return;
      }

      final settings = await _userProfileService.getSafetySettings();
      if (settings['fakeCallVolumeShortcutEnabled'] == true) {
        await _emergencyActionService.startFakeCallShortcutMonitor();
      } else {
        await _emergencyActionService.stopFakeCallShortcutMonitor();
      }
    } catch (_) {
      // Keep app startup usable even if Android denies foreground-service work.
    }
  }

  Future<void> _openPendingShortcutIfNeeded() async {
    try {
      final isPending =
          await _emergencyActionService.consumePendingFakeCallShortcut();
      if (isPending) {
        await _handleShortcutRequest();
      }
    } catch (_) {
      // The app can still be opened normally if consuming the pending flag fails.
    }
  }

  Future<void> _openPendingScheduledCallIfNeeded() async {
    try {
      final isPending =
          await _emergencyActionService.consumePendingScheduledFakeCall();
      if (isPending) {
        await _openCallScreen();
      }
    } catch (_) {
      // The app can still be opened normally if consuming the pending flag fails.
    }
  }

  Future<bool> _handleShortcutRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }

    final settings = await _userProfileService.getSafetySettings();
    if (settings['fakeCallVolumeShortcutEnabled'] != true) {
      return false;
    }

    return _openCallScreen();
  }

  /// Opens the incoming-call screen straight away.
  ///
  /// A scheduled call deliberately skips the volume-shortcut setting check:
  /// the user armed this call explicitly, so it rings even when the
  /// volume-button shortcut is switched off.
  Future<bool> _openCallScreen() async {
    if (_isNavigating) {
      return false;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      return false;
    }

    _isNavigating = true;
    navigator
        .pushNamed(
          AppRoutes.fakeCall,
          arguments: const FakeCallArguments(immediate: true),
        )
        .whenComplete(() {
      _isNavigating = false;
    });
    return true;
  }
}
