import 'package:amica_mobile_app/features/auth/services/user_profile_service.dart';
import 'package:amica_mobile_app/features/fake_call/services/voice_sos_service.dart';
import 'package:amica_mobile_app/features/plate_scan/services/vehicle_journey_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy profiles retain their original phrase', () {
    expect(
        UserProfileService.readSecretPhrases(
            {'secretPhrase': ' Call MY sister '}),
        ['call my sister']);
  });
  test('stored phrases are normalized, unique and skip invalid fields', () {
    expect(
        UserProfileService.readSecretPhrases({
          'secretPhrases': ['Help me', 'help  me', null, '', 'Call home']
        }),
        ['help me', 'call home']);
  });
  test('voice matches any configured phrase and reports which matched', () {
    final service = VoiceSosService();
    expect(
        service
            .matchingPhrase('please CALL home now', ['help me', 'call home']),
        'call home');
    expect(
        service
            .matchingPhrase('ordinary conversation', ['help me', 'call home']),
        isNull);
    expect(service.matchingPhrase('anything', ['']), isNull);
  });
  test('rating failures distinguish deployment and connectivity problems', () {
    expect(VehicleJourneyService.ratingErrorMessage('permission-denied'),
        contains('rules'));
    expect(VehicleJourneyService.ratingErrorMessage('unavailable'),
        contains('connection'));
  });
}
