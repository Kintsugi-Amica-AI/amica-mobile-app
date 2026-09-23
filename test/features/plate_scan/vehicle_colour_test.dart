import 'package:amica_mobile_app/features/plate_scan/models/detection.dart';
import 'package:amica_mobile_app/features/plate_scan/models/vehicle_profile.dart';
import 'package:amica_mobile_app/features/plate_scan/utils/vehicle_colour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A 400x300 "photo": [body] paint everywhere, a white plate in the
/// middle-bottom, and [background] around the vehicle.
img.Image photo(img.Color body, {img.Color? background}) {
  final image = img.Image(width: 400, height: 300);
  img.fill(image, color: background ?? body);
  img.fillRect(image, x1: 60, y1: 40, x2: 340, y2: 280, color: body);
  img.fillRect(image,
      x1: 160, y1: 200, x2: 240, y2: 230, color: img.ColorRgb8(245, 245, 245));
  return image;
}

const plate = PixelBox(160, 200, 240, 230);
const vehicle = PixelBox(60, 40, 340, 280);

void main() {
  group('VehicleColourClassifier.classifyPixel', () {
    test('names clear paint colours', () {
      const c = VehicleColourClassifier.classifyPixel;
      expect(c(245, 245, 245), VehicleColour.white);
      expect(c(175, 178, 182), VehicleColour.silver);
      expect(c(110, 112, 115), VehicleColour.grey);
      expect(c(20, 20, 22), VehicleColour.black);
      expect(c(200, 30, 30), VehicleColour.red);
      expect(c(100, 20, 30), VehicleColour.maroon);
      expect(c(240, 130, 20), VehicleColour.orange);
      expect(c(240, 200, 30), VehicleColour.yellow);
      expect(c(40, 140, 60), VehicleColour.green);
      expect(c(30, 80, 170), VehicleColour.blue);
      expect(c(110, 70, 40), VehicleColour.brown);
    });
  });

  group('VehicleColourClassifier.classify', () {
    test('reads body paint around the plate, not the white plate', () {
      final reading = VehicleColourClassifier.classify(
          photo(img.ColorRgb8(30, 80, 170)),
          plate: plate,
          vehicle: vehicle);
      expect(reading.colour, VehicleColour.blue);
      expect(reading.isReliable, isTrue);
    });

    test('a white car reads white, a red car in daylight is not a cast',
        () {
      expect(
          VehicleColourClassifier.classify(photo(img.ColorRgb8(240, 240, 238)),
                  plate: plate)
              .colour,
          VehicleColour.white);
      final red = VehicleColourClassifier.classify(
          photo(img.ColorRgb8(200, 30, 30)),
          plate: plate);
      expect(red.colour, VehicleColour.red);
      expect(red.colourCast, isFalse);
      expect(red.isReliable, isTrue);
    });

    test('a dark photo is flagged low light', () {
      final reading = VehicleColourClassifier.classify(
          photo(img.ColorRgb8(25, 25, 30),
              background: img.ColorRgb8(10, 10, 10)),
          plate: plate);
      expect(reading.lowLight, isTrue);
      expect(reading.isReliable, isFalse);
    });

    test('sodium street light turning a white car amber is a cast', () {
      final reading = VehicleColourClassifier.classify(
          photo(img.ColorRgb8(150, 95, 40),
              background: img.ColorRgb8(90, 55, 20)),
          plate: plate);
      expect(reading.colourCast, isTrue);
      expect(reading.isReliable, isFalse);
    });

    test('no plate and no vehicle means no colour', () {
      final reading =
          VehicleColourClassifier.classify(photo(img.ColorRgb8(30, 80, 170)));
      expect(reading.colour, isNull);
    });

    test('body region stays inside the vehicle and the image', () {
      final region = VehicleColourClassifier.bodyRegion(400, 300,
          plate: const PixelBox(0, 280, 80, 300), vehicle: vehicle)!;
      expect(region.left, greaterThanOrEqualTo(60));
      expect(region.bottom, lessThanOrEqualTo(280));
    });
  });
}
