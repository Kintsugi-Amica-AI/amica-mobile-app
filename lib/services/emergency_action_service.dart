import 'package:flutter/services.dart';

class EmergencyActionException implements Exception {
  const EmergencyActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmergencyActionService {
  const EmergencyActionService();

  static const MethodChannel _channel = MethodChannel(
    'com.kintsugi.amica/emergency_actions',
  );

  Future<void> prepareEmergencyPermissions() async {
    await _invokeBooleanMethod('prepareEmergencyPermissions');
  }

  /// Requests only the notification permission, for features that show an
  /// alert but have no reason to ask for SMS or phone access.
  Future<void> prepareNotificationPermission() async {
    await _invokeBooleanMethod('prepareNotificationPermission');
  }

  Future<void> sendEmergencySms({
    required String phone,
    required String message,
  }) async {
    await _invokeBooleanMethod(
      'sendSms',
      arguments: {
        'phone': phone,
        'message': message,
      },
    );
  }

  Future<void> startEmergencyCall({
    required String phone,
  }) async {
    await _invokeBooleanMethod(
      'startCall',
      arguments: {
        'phone': phone,
      },
    );
  }

  Future<void> vibrateTwice() async {
    await _invokeBooleanMethod('vibrateTwice');
  }

  Future<void> startJourneySafetyMonitor({
    required String journeyId,
    required String destinationName,
    required DateTime safetyCheckAt,
    required String emergencyPhone,
    required String emergencyMessage,
  }) async {
    await _invokeBooleanMethod(
      'startJourneySafetyMonitor',
      arguments: {
        'journeyId': journeyId,
        'destinationName': destinationName,
        'safetyCheckAtMillis': safetyCheckAt.millisecondsSinceEpoch,
        'emergencyPhone': emergencyPhone,
        'emergencyMessage': emergencyMessage,
      },
    );
  }

  Future<void> stopJourneySafetyMonitor() async {
    await _invokeBooleanMethod('stopJourneySafetyMonitor');
  }

  /// Starts native tracking of the distance to a bus drop-off.
  ///
  /// Runs in a foreground service so the alarm still sounds with Amica closed
  /// and the screen off, which is exactly when a rider needs it.
  Future<void> startStopAlertMonitor({
    required double dropOffLatitude,
    required double dropOffLongitude,
    required String dropOffName,
    required int alertDistanceMeters,
    bool alreadyAlerted = false,
  }) async {
    await _invokeBooleanMethod(
      'startStopAlertMonitor',
      arguments: {
        'dropOffLatitude': dropOffLatitude,
        'dropOffLongitude': dropOffLongitude,
        'dropOffName': dropOffName,
        'alertDistanceMeters': alertDistanceMeters,
        'alreadyAlerted': alreadyAlerted,
      },
    );
  }

  Future<void> stopStopAlertMonitor() async {
    await _invokeBooleanMethod('stopStopAlertMonitor');
  }

  Future<void> startFakeCallShortcutMonitor() async {
    await _invokeBooleanMethod('startFakeCallShortcutMonitor');
  }

  Future<void> stopFakeCallShortcutMonitor() async {
    await _invokeBooleanMethod('stopFakeCallShortcutMonitor');
  }

  Future<bool> consumePendingFakeCallShortcut() async {
    try {
      return await _channel.invokeMethod<bool>(
            'consumePendingFakeCallShortcut',
          ) ??
          false;
    } on PlatformException catch (error) {
      throw EmergencyActionException(
        error.message ?? 'Could not check the call shortcut.',
      );
    }
  }

  /// Arms a deterrent call for [delay] from now.
  ///
  /// The countdown is held by a native foreground service, so it still rings
  /// after the user leaves Amica or locks the phone — which is the whole point
  /// of scheduling a call before getting into a vehicle.
  Future<void> scheduleFakeCall({
    required Duration delay,
    required String callerName,
  }) async {
    await _invokeBooleanMethod(
      'scheduleFakeCall',
      arguments: {
        'delaySeconds': delay.inSeconds,
        'callerName': callerName,
      },
    );
  }

  Future<void> cancelScheduledFakeCall() async {
    await _invokeBooleanMethod('cancelScheduledFakeCall');
  }

  /// Time left on an armed schedule, or [Duration.zero] when nothing is
  /// pending. Lets the call screen restore its countdown after being closed.
  Future<Duration> scheduledFakeCallRemaining() async {
    try {
      final seconds = await _channel.invokeMethod<int>(
            'scheduledFakeCallRemainingSeconds',
          ) ??
          0;
      return Duration(seconds: seconds < 0 ? 0 : seconds);
    } on PlatformException {
      return Duration.zero;
    } on MissingPluginException {
      return Duration.zero;
    }
  }

  Future<bool> consumePendingScheduledFakeCall() async {
    try {
      return await _channel.invokeMethod<bool>(
            'consumePendingScheduledFakeCall',
          ) ??
          false;
    } on PlatformException catch (error) {
      throw EmergencyActionException(
        error.message ?? 'Could not check the scheduled call.',
      );
    }
  }

  Future<void> setCallProximityEnabled({required bool enabled}) async {
    await _invokeBooleanMethod(
      'setCallProximityEnabled',
      arguments: {'enabled': enabled},
    );
  }

  Future<void> _invokeBooleanMethod(
    String method, {
    Map<String, Object?> arguments = const {},
  }) async {
    try {
      await _channel.invokeMethod<bool>(method, arguments);
    } on PlatformException catch (error) {
      throw EmergencyActionException(
        error.message ?? 'Emergency action failed.',
      );
    }
  }
}
