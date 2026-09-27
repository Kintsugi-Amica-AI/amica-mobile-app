import 'package:amica_mobile_app/features/plate_scan/models/vehicle_profile.dart';
import 'package:amica_mobile_app/features/plate_scan/utils/vehicle_match.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleTypeReading coco(String label, [double confidence = 0.8]) =>
    VehicleTypeReading(
      label: label,
      possibleKinds: VehicleTypeReading.kindsForLabel(label)!,
      confidence: confidence,
    );

VehicleColourReading paint(VehicleColour colour,
        {double share = 0.7, bool lowLight = false, bool cast = false}) =>
    VehicleColourReading(
        colour: colour, share: share, lowLight: lowLight, colourCast: cast);

void main() {
  group('VehicleMatcher', () {
    test('matches when type and colour fit what she was told', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(
            kind: VehicleKind.car, colour: VehicleColour.white),
        type: coco('car'),
        colour: paint(VehicleColour.white),
      );
      expect(result.outcome, VehicleMatchOutcome.match);
      expect(result.checkedType, isTrue);
      expect(result.checkedColour, isTrue);
    });

    test('a red van when told a white car is a mismatch on both', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(
            kind: VehicleKind.car, colour: VehicleColour.white),
        type: coco('truck'),
        colour: paint(VehicleColour.red),
      );
      expect(result.outcome, VehicleMatchOutcome.mismatch);
      expect(result.mismatches.map((m) => m.aspect),
          [VehicleMatchAspect.type, VehicleMatchAspect.colour]);
      expect(result.mismatches.first.seenKind, VehicleKind.lorry);
    });

    test('a COCO "car" never contradicts a told van or three-wheeler', () {
      for (final kind in [VehicleKind.van, VehicleKind.threeWheeler]) {
        final result = VehicleMatcher.evaluate(
          told: VehicleExpectation(kind: kind),
          type: coco('car'),
          colour: null,
        );
        expect(result.outcome, VehicleMatchOutcome.match, reason: '$kind');
      }
    });

    test('a trained three_wheeler class does contradict a told car', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(kind: VehicleKind.car),
        type: coco('three_wheeler'),
        colour: null,
      );
      expect(result.outcome, VehicleMatchOutcome.mismatch);
    });

    test('look-alike colours are never a mismatch', () {
      for (final pair in [
        (VehicleColour.white, VehicleColour.silver),
        (VehicleColour.silver, VehicleColour.grey),
        (VehicleColour.grey, VehicleColour.black),
        (VehicleColour.red, VehicleColour.maroon),
      ]) {
        final result = VehicleMatcher.evaluate(
          told: VehicleExpectation(colour: pair.$1),
          type: null,
          colour: paint(pair.$2),
        );
        expect(result.outcome, VehicleMatchOutcome.match, reason: '$pair');
      }
    });

    test('at night colour is not compared: not sure, never a false alarm',
        () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(colour: VehicleColour.white),
        type: null,
        colour: paint(VehicleColour.orange, lowLight: true),
      );
      expect(result.outcome, VehicleMatchOutcome.notSure);
      expect(result.notSureReasons, contains(VehicleNotSureReason.lowLight));
    });

    test('street-light colour cast is reported as not sure', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(colour: VehicleColour.white),
        type: coco('car', 0.2),
        colour: paint(VehicleColour.orange, cast: true),
      );
      expect(result.outcome, VehicleMatchOutcome.notSure);
      expect(result.notSureReasons, contains(VehicleNotSureReason.colourCast));
    });

    test('weak type readings are ignored', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(kind: VehicleKind.bus),
        type: coco('car', 0.4),
        colour: null,
      );
      expect(result.outcome, VehicleMatchOutcome.notSure);
    });

    test('nothing told and no community pattern is not sure', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(),
        type: coco('car'),
        colour: paint(VehicleColour.blue),
      );
      expect(result.outcome, VehicleMatchOutcome.notSure);
      expect(result.notSureReasons,
          {VehicleNotSureReason.nothingToCompare});
    });

    test('the community pattern flags a plate moved to another vehicle', () {
      final result = VehicleMatcher.evaluate(
        told: const VehicleExpectation(),
        type: coco('truck'),
        colour: paint(VehicleColour.red),
        community: const CommunityVehicleProfile(
          usualKind: VehicleKind.car,
          usualColour: VehicleColour.white,
          observationCount: 7,
        ),
      );
      expect(result.outcome, VehicleMatchOutcome.mismatch);
      expect(result.mismatches.every((m) => m.source ==
          VehicleMatchSource.community), isTrue);
    });
  });

  group('CommunityVehicleProfile.fromMap', () {
    test('reads the server-written profile and ignores junk', () {
      final profile = CommunityVehicleProfile.fromMap({
        'usualType': 'three_wheeler',
        'usualColour': 'green',
        'observationCount': 5,
      });
      expect(profile.usualKind, VehicleKind.threeWheeler);
      expect(profile.usualColour, VehicleColour.green);
      expect(profile.observationCount, 5);
      expect(CommunityVehicleProfile.fromMap('x').hasPattern, isFalse);
      expect(
          CommunityVehicleProfile.fromMap({'usualType': 'spaceship'})
              .hasPattern,
          isFalse);
    });
  });
}
