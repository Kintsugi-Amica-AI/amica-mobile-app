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
