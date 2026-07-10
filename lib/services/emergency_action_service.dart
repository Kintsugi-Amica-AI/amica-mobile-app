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
