import 'package:amica_mobile_app/features/journey/models/journey.dart';
import 'package:amica_mobile_app/features/journey/models/location_data_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Journey.fromMap', () {
    test('reads the fields the timer and safety check screens rely on', () {
      final estimatedEndTime = DateTime(2026, 3, 4, 22);
      final journey = Journey.fromMap({
        'id': 'journey-1',
        'userId': 'user-1',
        'journeyType': 'taxi',
        'status': 'active',
        'estimatedDurationMinutes': 25,
        'estimatedEndTime': estimatedEndTime,
        'destination': {
          'name': 'Home',
          'address': '12 Galle Road',
          'latitude': 6.9271,
          'longitude': 79.8612,
        },
      }, 'fallback-id');

      expect(journey.id, 'journey-1');
      expect(journey.journeyType, 'taxi');
      expect(journey.isActive, isTrue);
      expect(journey.estimatedDurationMinutes, 25);
      expect(journey.estimatedEndTime, estimatedEndTime);
      expect(journey.destinationName, 'Home');
      expect(journey.destinationLocation?.latitude, 6.9271);
    });

    test('falls back to the document id and safe defaults', () {
      final journey = Journey.fromMap(const {}, 'fallback-id');

      expect(journey.id, 'fallback-id');
      expect(journey.journeyType, 'walk');
      expect(journey.status, 'active');
      expect(journey.estimatedDurationMinutes, 30);
      expect(journey.destinationName, 'Destination');
      expect(journey.safetyCheck['required'], isTrue);
    });

    test('non-active statuses are not treated as active', () {
      for (final status in ['safe', 'sos', 'cancelled']) {
        final journey = Journey.fromMap({'status': status}, 'id');
        expect(journey.isActive, isFalse, reason: 'status "$status"');
      }
    });
  });

  group('Journey.destinationLocation', () {
    test('is null when the destination was saved without coordinates', () {
      // startJourney writes a 0/0 placeholder when the user never pinned the
      // destination, which must not be drawn on the map as a real location.
      final journey = Journey.fromMap({
        'destination': {'name': 'Home', 'latitude': 0, 'longitude': 0},
      }, 'id');

      expect(journey.destinationLocation, isNull);
    });

    test('is null when coordinates are missing entirely', () {
      final journey = Journey.fromMap({
        'destination': {'name': 'Home'},
      }, 'id');

      expect(journey.destinationLocation, isNull);
    });

    test('falls back to the destination name when no address was saved', () {
      final journey = Journey.fromMap({
        'destination': {
          'name': 'Home',
          'latitude': 6.9271,
          'longitude': 79.8612,
        },
      }, 'id');

      expect(journey.destinationLocation?.address, 'Home');
    });
  });

  group('Journey stop alert fields', () {
    test('reads an armed bus stop alert', () {
      final journey = Journey.fromMap({
        'journeyType': 'bus',
        'stopAlert': {
          'enabled': true,
          'alertDistanceMeters': 3000,
          'alertedAt': null,
        },
      }, 'id');

      expect(journey.isStopAlertRide, isTrue);
      expect(journey.alertDistanceMeters, 3000);
      expect(journey.stopAlertTriggered, isFalse);
    });

    test('an ordinary timer journey is not a stop alert ride', () {
      // The two kinds share the journeys collection, so the timer screen must
      // not pick up a bus ride and a bus ride must not pick up a timer journey.
      final journey = Journey.fromMap(const {'journeyType': 'walk'}, 'id');

      expect(journey.isStopAlertRide, isFalse);
      expect(journey.stopAlertTriggered, isFalse);
    });

    test('a journey with a timer and a stop alert keeps both', () {
      final journey = Journey.fromMap(const {
        'journeyType': 'bus',
        'safetyCheck': {'required': true},
        'stopAlert': {
          'enabled': true,
          'dropOff': {'name': 'Malabe stop', 'latitude': 6.9, 'longitude': 79.9},
        },
        'destination': {'name': 'Office', 'latitude': 6.95, 'longitude': 79.95},
      }, 'id');

      expect(journey.isStopAlertRide, isTrue);
      expect(journey.hasSafetyTimer, isTrue);
      expect(journey.isStopAlertOnly, isFalse);
      // The alarm counts down to the stop, not the final destination.
      expect(journey.stopAlertTargetName, 'Malabe stop');
      expect(journey.stopAlertTarget?.latitude, 6.9);
    });

    test('a stop alert only ride has no timer and alarms at its destination',
        () {
      final journey = Journey.fromMap(const {
        'journeyType': 'bus',
        'safetyCheck': {'required': false},
        'stopAlert': {'enabled': true},
        'destination': {'name': 'Kandy', 'latitude': 7.29, 'longitude': 80.63},
      }, 'id');

      expect(journey.isStopAlertOnly, isTrue);
      expect(journey.stopAlertTargetName, 'Kandy');
      expect(journey.stopAlertTarget?.longitude, 80.63);
    });

    test('counts how many times the route was re-planned', () {
      expect(Journey.fromMap(const {}, 'id').routeChangeCount, 0);
      expect(
        Journey.fromMap(const {
          'route': {'changeCount': 2},
        }, 'id').routeChangeCount,
        2,
      );
    });

    test('a bus journey without a stopAlert map is not a stop alert ride', () {
      final journey = Journey.fromMap(const {'journeyType': 'bus'}, 'id');

      expect(journey.isStopAlertRide, isFalse);
    });

    test('falls back to the 2 km default for a missing or invalid distance',
        () {
      expect(
        Journey.fromMap(const {
          'stopAlert': {'enabled': true},
        }, 'id').alertDistanceMeters,
        Journey.defaultAlertDistanceMeters,
      );
      expect(
        Journey.fromMap(const {
          'stopAlert': {'enabled': true, 'alertDistanceMeters': 0},
        }, 'id').alertDistanceMeters,
        Journey.defaultAlertDistanceMeters,
      );
      expect(
        Journey.fromMap(const {
          'stopAlert': {'enabled': true, 'alertDistanceMeters': 'far'},
        }, 'id').alertDistanceMeters,
        Journey.defaultAlertDistanceMeters,
      );
    });

    test('reports the alarm as already sounded once alertedAt is written', () {
      final journey = Journey.fromMap({
        'stopAlert': {
          'enabled': true,
          'alertedAt': DateTime(2026, 3, 4, 21, 30),
        },
      }, 'id');

      expect(journey.stopAlertTriggered, isTrue);
    });
  });

  group('LocationDataModel', () {
    test('reads numeric coordinates stored as ints', () {
      final location = LocationDataModel.fromMap(const {
        'latitude': 6,
        'longitude': 79,
        'address': 'Colombo',
      });

      expect(location.latitude, 6.0);
      expect(location.longitude, 79.0);
      expect(location.address, 'Colombo');
    });

    test('defaults to zero coordinates for a missing map', () {
      final location = LocationDataModel.fromMap(null);

      expect(location.latitude, 0);
      expect(location.longitude, 0);
      expect(location.address, '');
    });

    test('copyWith replaces only the given fields', () {
      final updatedAt = DateTime(2026, 3, 4);
      final location = LocationDataModel(
        latitude: 6.9271,
        longitude: 79.8612,
        address: '',
        updatedAt: updatedAt,
      );

      final copy = location.copyWith(address: 'Home');

      expect(copy.address, 'Home');
      expect(copy.latitude, 6.9271);
      expect(copy.updatedAt, updatedAt);
    });
  });
}
