import 'dart:typed_data';

import 'package:amica_mobile_app/features/plate_scan/models/detection.dart';
import 'package:amica_mobile_app/features/plate_scan/models/vehicle_profile.dart';
import 'package:amica_mobile_app/features/plate_scan/services/vehicle_inspector.dart';
import 'package:amica_mobile_app/features/plate_scan/services/vehicle_observation_service.dart';
import 'package:amica_mobile_app/features/plate_scan/services/yolo_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodeYoloOutput maps letterboxed boxes back to the photo', () {
    // 2 classes, 3 anchors, 320 input; a 640x480 photo is scaled by 0.5
    // and padded 40 px top and bottom.
    const anchors = 3;
    final out = Float32List(6 * anchors);
    void put(int a, List<double> v) {
      for (var c = 0; c < v.length; c++) {
        out[c * anchors + a] = v[c];
      }
    }

    put(0, [160, 160, 100, 50, 0.9, 0.1]); // class 0 in the middle
    put(1, [162, 161, 100, 50, 0.8, 0.1]); // duplicate, suppressed
    put(2, [50, 60, 20, 20, 0.1, 0.2]); // below the score floor

    final found = decodeYoloOutput(out,
        channels: 6,
        anchors: anchors,
        labels: const ['car', 'bus'],
        inputSize: 320,
        scale: 0.5,
        padX: 0,
        padY: 40,
        imageWidth: 640,
        imageHeight: 480);
    expect(found, hasLength(1));
    expect(found.single.label, 'car');
    expect(found.single.box.left, closeTo(220, 0.01));
    expect(found.single.box.top, closeTo(190, 0.01));
    expect(found.single.box.right, closeTo(420, 0.01));
    expect(found.single.box.bottom, closeTo(290, 0.01));
  });

  test('decodeYoloOutput accepts 0-1 coordinates too', () {
    final out = Float32List(5)
      ..setAll(0, [0.5, 0.5, 0.25, 0.1, 0.9]);
    final found = decodeYoloOutput(out,
        channels: 5,
        anchors: 1,
        labels: const ['plate'],
        inputSize: 320,
        scale: 1,
        padX: 0,
        padY: 0,
        imageWidth: 320,
        imageHeight: 320);
    expect(found.single.box.width, closeTo(80, 0.01));
  });

  test('pickVehicle prefers the vehicle that holds the plate', () {
    const near = Detection(
        label: 'car', score: 0.6, box: PixelBox(100, 100, 300, 300));
    const big = Detection(
        label: 'bus', score: 0.9, box: PixelBox(300, 0, 640, 480));
    const person = Detection(
        label: 'person', score: 0.99, box: PixelBox(0, 0, 640, 480));
    expect(
        VehicleInspector.pickVehicle([near, big, person], 640, 480,
                plate: const PixelBox(180, 250, 220, 270))
            ?.label,
        'car');
    expect(VehicleInspector.pickVehicle([near, big, person], 640, 480)?.label,
        'bus');
    expect(VehicleInspector.pickVehicle([person], 640, 480), isNull);
  });

  test('only confident readings are shared with the community', () {
    VehicleTypeReading type(String label, double c) => VehicleTypeReading(
        label: label,
        possibleKinds: VehicleTypeReading.kindsForLabel(label)!,
        confidence: c);
    expect(
        VehicleObservationService.observationFields(VehicleInspection(
          type: type('truck', 0.8),
          colour: const VehicleColourReading(
              colour: VehicleColour.red, share: 0.6),
        )),
        {'vehicleType': 'lorry', 'colour': 'red'});
    expect(
        VehicleObservationService.observationFields(VehicleInspection(
          type: type('car', 0.3),
          colour: const VehicleColourReading(
              colour: VehicleColour.red, share: 0.6, lowLight: true),
        )),
        isNull);
  });
}
