import '../models/sos_alert.dart';

class SosService {
  Future<SosAlert> sendSos({
    required String userId,
    required String triggerType,
    double? latitude,
    double? longitude,
  }) async {
    // TODO: Send SOS payload to Firebase backend.
    return SosAlert(
      id: 'demo-sos',
      userId: userId,
      triggerType: triggerType,
      createdAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> cancelSos(String alertId) async {
    // TODO: Mark SOS alert as cancelled when policy allows.
  }
}
