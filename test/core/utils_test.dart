import 'package:amica_mobile_app/core/utils/date_time_utils.dart';
import 'package:amica_mobile_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTimeUtils.formatDuration', () {
    test('formats the journey countdown as mm:ss under an hour', () {
      expect(DateTimeUtils.formatDuration(Duration.zero), '00:00');
      expect(
        DateTimeUtils.formatDuration(const Duration(seconds: 45)),
        '00:45',
      );
      expect(
        DateTimeUtils.formatDuration(const Duration(minutes: 29, seconds: 5)),
        '29:05',
      );
    });

    test('includes hours for long journeys', () {
      expect(
        DateTimeUtils.formatDuration(
          const Duration(hours: 2, minutes: 5, seconds: 9),
        ),
        '2:05:09',
      );
    });
  });

  group('DateTimeUtils.formatDateTime', () {
    test('zero-pads every part', () {
      expect(
        DateTimeUtils.formatDateTime(DateTime(2026, 3, 4, 9, 7)),
        '2026-03-04 09:07',
      );
    });
  });

  group('Validators.required', () {
    test('rejects null and whitespace-only values', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('names the field in the message', () {
      expect(
        Validators.required('', fieldName: 'Secret phrase'),
        'Secret phrase is required',
      );
    });

    test('accepts a real value', () {
      expect(Validators.required('Amma'), isNull);
    });
  });

  group('Validators.email', () {
    test('accepts a well-formed address', () {
      expect(Validators.email('someone@example.com'), isNull);
      expect(Validators.email('  someone@example.com  '), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('someone'), isNotNull);
      expect(Validators.email('someone@example'), isNotNull);
      expect(Validators.email('a@b@example.com'), isNotNull);
    });

    test('rejects a missing address', () {
      expect(Validators.email(null), 'Email is required');
    });
  });

  group('Validators.phone', () {
    test('accepts numbers with formatting characters', () {
      expect(Validators.phone('+94 77 123 4567'), isNull);
      expect(Validators.phone('077-1234567'), isNull);
    });

    test('rejects numbers that are too short to dial', () {
      expect(Validators.phone('12345'), isNotNull);
    });

    test('rejects a missing number', () {
      expect(Validators.phone(null), 'Phone number is required');
    });
  });
}
