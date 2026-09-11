import 'package:amica_mobile_app/features/stop_alert/services/stop_alert_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = StopAlertCalculator();

  // Two real Colombo-area points roughly 17 km apart, used so the distance
  // maths is checked against something other than itself.
  const colomboFortLat = 6.9344;
  const colomboFortLng = 79.8428;
  const malabeLat = 6.9036;
  const malabeLng = 79.9547;

  group('distanceInMeters', () {
    test('is zero for the same point', () {
      expect(
        calculator.distanceInMeters(
          colomboFortLat,
          colomboFortLng,
          colomboFortLat,
          colomboFortLng,
        ),
        0,
      );
    });

    test('matches a known real-world distance', () {
      final meters = calculator.distanceInMeters(
        colomboFortLat,
        colomboFortLng,
        malabeLat,
        malabeLng,
      );

      // Colombo Fort to Malabe is about 12.8 km as the crow flies.
      expect(meters, greaterThan(12000));
      expect(meters, lessThan(14000));
    });

    test('is symmetric', () {
      final there = calculator.distanceInMeters(
        colomboFortLat,
        colomboFortLng,
        malabeLat,
        malabeLng,
      );
      final back = calculator.distanceInMeters(
        malabeLat,
        malabeLng,
        colomboFortLat,
        colomboFortLng,
      );

      expect((there - back).abs(), lessThan(0.001));
    });

    test('handles a short hop of a few hundred metres', () {
      // Roughly 0.005 degrees of latitude, about 555 m.
      final meters = calculator.distanceInMeters(
        colomboFortLat,
        colomboFortLng,
        colomboFortLat + 0.005,
        colomboFortLng,
      );

      expect(meters, greaterThan(500));
      expect(meters, lessThan(600));
    });
  });

  group('shouldAlert', () {
    test('does not alert while still further than the alert distance', () {
      expect(
        calculator.shouldAlert(
          distanceMeters: 2500,
          alertDistanceMeters: 2000,
          alreadyAlerted: false,
        ),
        isFalse,
      );
    });

    test('alerts on reaching the alert distance', () {
      expect(
        calculator.shouldAlert(
          distanceMeters: 2000,
          alertDistanceMeters: 2000,
          alreadyAlerted: false,
        ),
        isTrue,
      );
      expect(
        calculator.shouldAlert(
          distanceMeters: 1800,
          alertDistanceMeters: 2000,
          alreadyAlerted: false,
        ),
        isTrue,
      );
    });

    test('alerts only once per ride', () {
      // A bus weaving in and out of the radius, or a jittery GPS fix, must not
      // set the alarm off over and over.
      expect(
        calculator.shouldAlert(
          distanceMeters: 1500,
          alertDistanceMeters: 2000,
          alreadyAlerted: true,
        ),
        isFalse,
      );
    });

    test('still alerts when the rider is almost at the stop', () {
      expect(
        calculator.shouldAlert(
          distanceMeters: 0,
          alertDistanceMeters: 2000,
          alreadyAlerted: false,
        ),
        isTrue,
      );
    });
  });

  group('isAlreadyWithinAlertDistance', () {
    test('flags a stop that is already inside the radius at setup', () {
      // Arming a 2 km alert for a stop 1.5 km away would sound immediately.
      expect(
        calculator.isAlreadyWithinAlertDistance(
          distanceMeters: 1500,
          alertDistanceMeters: 2000,
        ),
        isTrue,
      );
    });

    test('does not flag a stop further out than the radius', () {
      expect(
        calculator.isAlreadyWithinAlertDistance(
          distanceMeters: 8000,
          alertDistanceMeters: 2000,
        ),
        isFalse,
      );
    });
  });

  group('progress', () {
    test('is zero at the start of the ride', () {
      expect(
        calculator.progress(
          startDistanceMeters: 10000,
          currentDistanceMeters: 10000,
        ),
        0,
      );
    });

    test('is one at the stop', () {
      expect(
        calculator.progress(
          startDistanceMeters: 10000,
          currentDistanceMeters: 0,
        ),
        1,
      );
    });

    test('is halfway at half the distance', () {
      expect(
        calculator.progress(
          startDistanceMeters: 10000,
          currentDistanceMeters: 5000,
        ),
        0.5,
      );
    });

    test('clamps when the bus overshoots the stop', () {
      expect(
        calculator.progress(
          startDistanceMeters: 10000,
          currentDistanceMeters: -500,
        ),
        1,
      );
    });

    test('clamps when the bus first travels away from the stop', () {
      expect(
        calculator.progress(
          startDistanceMeters: 10000,
          currentDistanceMeters: 12000,
        ),
        0,
      );
    });

    test('is null when there is no starting distance to measure against', () {
      expect(
        calculator.progress(
          startDistanceMeters: 0,
          currentDistanceMeters: 0,
        ),
        isNull,
      );
    });
  });

  group('formatDistance', () {
    test('uses metres under a kilometre', () {
      expect(calculator.formatDistance(0), '0 m');
      expect(calculator.formatDistance(240.4), '240 m');
      expect(calculator.formatDistance(999), '999 m');
    });

    test('uses one decimal kilometre above a kilometre', () {
      expect(calculator.formatDistance(1000), '1.0 km');
      expect(calculator.formatDistance(2000), '2.0 km');
      expect(calculator.formatDistance(12840), '12.8 km');
    });

    test('drops the decimal for very long distances', () {
      expect(calculator.formatDistance(150000), '150 km');
    });

    test('reports unknown for a nonsense distance', () {
      expect(calculator.formatDistance(-1), 'Unknown');
      expect(calculator.formatDistance(double.nan), 'Unknown');
    });
  });

  group('formatAlertDistance', () {
    test('labels every offered option without a trailing decimal', () {
      expect(calculator.formatAlertDistance(1000), '1 km');
      expect(calculator.formatAlertDistance(2000), '2 km');
      expect(calculator.formatAlertDistance(5000), '5 km');
    });

    test('labels sub-kilometre distances in metres', () {
      expect(calculator.formatAlertDistance(500), '500 m');
    });

    test('every offered option gets a label', () {
      for (final meters in StopAlertCalculator.alertDistanceOptionsMeters) {
        expect(calculator.formatAlertDistance(meters), isNotEmpty);
      }
    });
  });

  group('alertDistanceOptionsMeters', () {
    test('are positive and ordered shortest first', () {
      const options = StopAlertCalculator.alertDistanceOptionsMeters;

      expect(options, isNotEmpty);
      expect(options.first, greaterThan(0));
      for (var i = 1; i < options.length; i++) {
        expect(options[i], greaterThan(options[i - 1]));
      }
    });

    test('includes the 2 km default', () {
      expect(StopAlertCalculator.alertDistanceOptionsMeters, contains(2000));
    });
  });
}
