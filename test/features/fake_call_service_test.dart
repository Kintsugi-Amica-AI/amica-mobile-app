import 'package:amica_mobile_app/features/fake_call/models/fake_call_session.dart';
import 'package:amica_mobile_app/features/fake_call/services/fake_call_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FakeCallService();

  group('buildFakeCallSession', () {
    test('uses the configured caller identity', () {
      final session = service.buildFakeCallSession(
        callerName: '  Amma  ',
        callerNumber: ' +94 771234567 ',
        status: 'active',
      );

      expect(session.callerName, 'Amma');
      expect(session.callerNumber, '+94 771234567');
      expect(session.status, 'active');
      expect(session.voiceSosTriggered, isFalse);
      expect(session.id, startsWith('fake-call-'));
    });

    test('falls back to defaults for missing or blank values', () {
      final session = service.buildFakeCallSession(
        callerName: '   ',
        callerNumber: null,
      );

      expect(session.callerName, service.getDefaultCallerName());
      expect(session.callerNumber, service.getDefaultCallerNumber());
      expect(session.status, 'incoming');
    });
  });

  group('formatCallDuration', () {
    test('formats under an hour as mm:ss', () {
      expect(service.formatCallDuration(Duration.zero), '00:00');
      expect(service.formatCallDuration(const Duration(seconds: 9)), '00:09');
      expect(
        service.formatCallDuration(const Duration(minutes: 3, seconds: 7)),
        '03:07',
      );
    });

    test('includes hours once the call passes an hour', () {
      expect(
        service.formatCallDuration(
          const Duration(hours: 1, minutes: 2, seconds: 5),
        ),
        '1:02:05',
      );
    });
  });

  group('formatScheduleDelay', () {
    test('labels sub-minute delays in seconds', () {
      expect(service.formatScheduleDelay(const Duration(seconds: 15)), '15s');
      expect(service.formatScheduleDelay(const Duration(seconds: 30)), '30s');
    });

    test('labels longer delays in minutes', () {
      expect(service.formatScheduleDelay(const Duration(minutes: 1)), '1 min');
      expect(service.formatScheduleDelay(const Duration(minutes: 5)), '5 min');
    });

    test('labels every offered schedule option', () {
      for (final delay in FakeCallService.scheduleDelayOptions) {
        expect(service.formatScheduleDelay(delay), isNotEmpty);
      }
    });
  });

  group('scheduleDelayOptions', () {
    test('are positive and ordered shortest first', () {
      const options = FakeCallService.scheduleDelayOptions;

      expect(options, isNotEmpty);
      expect(options.first, greaterThan(Duration.zero));
      for (var i = 1; i < options.length; i++) {
        expect(options[i], greaterThan(options[i - 1]));
      }
    });
  });

  group('FakeCallSession', () {
    test('round-trips through a map', () {
      final startedAt = DateTime(2026, 3, 4, 21, 30);
      final session = FakeCallSession(
        id: 'fake-call-1',
        callerName: 'Amma',
        callerNumber: '+94 771234567',
        status: 'active',
        startedAt: startedAt,
        voiceSosTriggered: true,
        sosAlertId: 'alert-1',
        metadata: const {'source': 'scheduled'},
      );

      final restored = FakeCallSession.fromMap(session.toMap());

      expect(restored.id, 'fake-call-1');
      expect(restored.callerName, 'Amma');
      expect(restored.status, 'active');
      expect(restored.startedAt, startedAt);
      expect(restored.voiceSosTriggered, isTrue);
      expect(restored.sosAlertId, 'alert-1');
      expect(restored.metadata['source'], 'scheduled');
    });

    test('applies defaults for an empty map', () {
      final session = FakeCallSession.fromMap(const {});

      expect(session.callerName, 'Amica Friend');
      expect(session.callerNumber, '+94 700 000 000');
      expect(session.status, 'incoming');
      expect(session.voiceSosTriggered, isFalse);
      expect(session.sosAlertId, isNull);
    });
  });
}
