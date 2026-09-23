import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/detection.dart';
import '../models/vehicle_profile.dart';
import '../utils/vehicle_colour.dart';
import '../utils/vision_log.dart';
import 'yolo_detector.dart';

/// What the camera saw of the vehicle itself, next to its plate.
class VehicleInspection {
  const VehicleInspection({
    this.plateBox,
    this.vehicleBox,
    this.type,
    this.colour,
  });

  static const empty = VehicleInspection();

  final PixelBox? plateBox;
  final PixelBox? vehicleBox;
  final VehicleTypeReading? type;
  final VehicleColourReading? colour;
}

/// On-device vision for Scan before you ride: finds the plate in the
/// whole photo, then reads the vehicle's type and colour. Nothing leaves
/// the phone; only the resulting words (type, colour) are ever saved.
class VehicleInspector {
  const VehicleInspector();

  /// Trained in amica-ai-core/plate_ocr/training. Optional: without it the
  /// scan frame crop is used, exactly as before.
  static const String plateModel = 'assets/models/plate_detector.tflite';
  static const String plateLabels = 'assets/models/plate_detector.txt';

  /// Sri Lanka fine-tune with three-wheelers, vans and lorries. Optional:
  /// when absent the bundled COCO model is used.
  static const String localVehicleModel =
      'assets/models/vehicle_detector_lk.tflite';
  static const String localVehicleLabels =
      'assets/models/vehicle_detector_lk.txt';

  /// YOLOv8n trained on COCO (car, motorcycle, bus, truck, ...).
  static const String cocoVehicleModel =
      'assets/models/vehicle_detector.tflite';
  static const String cocoVehicleLabels = 'assets/models/vehicle_detector.txt';

  static const double minPlateScore = 0.35;
  static const double minVehicleScore = 0.30;

  /// Decodes [path], applies its EXIF rotation and caps the long side, so
  /// every later step works on one upright image. Null when unreadable.
  Future<img.Image?> loadUpright(String path) async {
    final watch = Stopwatch()..start();
    try {
      final image = await compute(_decodeUpright, path);
      visionLog('photo decoded ${image?.width}x${image?.height} '
          'in ${watch.elapsedMilliseconds}ms');
      return image;
    } catch (error) {
      visionLog('photo decode failed ($error)');
      return null;
    }
  }

  /// The most likely plate in [image], or null when no plate model is
  /// installed or nothing plate-like was found.
  Future<PixelBox?> findPlate(img.Image image) async {
    final detector = await YoloDetector.load(plateModel, plateLabels);
    if (detector == null) return null;
    try {
      final plates = await detector.detect(image,
          minScore: minPlateScore, onlyLabels: {'plate', 'number_plate'});
      if (plates.isEmpty) return null;
      // Prefer confident, large and central plates: the one she is aiming
      // at, not a plate on a car in the background.
      Detection best = plates.first;
      var bestValue = -1.0;
      for (final plate in plates) {
        final value = plate.score *
            math.sqrt(plate.box.area) *
            _centrality(plate.box, image.width, image.height);
        if (value > bestValue) {
          bestValue = value;
          best = plate;
        }
      }
      visionLog('plate found at ${best.box} (score '
          '${best.score.toStringAsFixed(2)})');
      return best.box;
    } catch (error) {
      visionLog('plate detection failed ($error)');
      return null;
    }
  }

  /// Crops [box] out of [image] (with a margin so no character is clipped),
  /// enlarges small crops so ML Kit sees big enough letters, and writes a
  /// JPEG next to [sourcePath]. Returns the new path, or null on failure.
  Future<String?> writeCrop(
    img.Image image,
    PixelBox box,
    String sourcePath, {
    double margin = 0.12,
  }) async {
    try {
      final bytes = await compute(
          _cropAndEncode, (image: image, box: box.inflate(margin)));
      if (bytes == null) return null;
      final path =
          '$sourcePath.crop.${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(bytes);
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Reads the vehicle's type and colour. [plate] is where the plate was
  /// found, when known; it anchors both the vehicle choice and the colour
  /// sample.
  Future<VehicleInspection> inspect(img.Image image, {PixelBox? plate}) async {
    Detection? vehicle;
    try {
      final detector =
          await YoloDetector.load(localVehicleModel, localVehicleLabels) ??
              await YoloDetector.load(cocoVehicleModel, cocoVehicleLabels);
      if (detector != null) {
        final found = await detector.detect(image, minScore: minVehicleScore);
        vehicle = pickVehicle(found, image.width, image.height, plate: plate);
      }
    } catch (error) {
      visionLog('vehicle detection failed ($error)');
    }

    final type = vehicle == null
        ? null
        : VehicleTypeReading(
            label: vehicle.label,
            possibleKinds: VehicleTypeReading.kindsForLabel(vehicle.label)!,
            confidence: vehicle.score,
          );
    VehicleColourReading? colour;
    if (plate != null || vehicle != null) {
      colour = VehicleColourClassifier.classify(image,
          plate: plate, vehicle: vehicle?.box);
    }
    visionLog('inspection: vehicle '
        '${vehicle == null ? 'none' : '${vehicle.label} ${vehicle.score.toStringAsFixed(2)} at ${vehicle.box}'}'
        ', colour ${colour == null ? 'not read' : '${colour.colour?.id ?? 'unclear'} '
            '(share ${colour.share.toStringAsFixed(2)}, lowLight ${colour.lowLight}, '
            'cast ${colour.colourCast})'}');
    return VehicleInspection(
      plateBox: plate,
      vehicleBox: vehicle?.box,
      type: type,
      colour: colour,
    );
  }

  /// The vehicle the plate belongs to: the one whose box holds the plate,
  /// otherwise the biggest, most central vehicle in view.
  @visibleForTesting
  static Detection? pickVehicle(
    List<Detection> detections,
    int width,
    int height, {
    PixelBox? plate,
  }) {
    final vehicles = detections
        .where((d) => VehicleTypeReading.kindsForLabel(d.label) != null)
        .toList();
    if (vehicles.isEmpty) return null;
    if (plate != null) {
      final holding = vehicles
          .where((v) => v.box.contains(plate.centerX, plate.centerY))
          .toList();
      if (holding.isNotEmpty) {
        // Nested boxes (a car on a car-carrier): the tightest one.
        holding.sort((a, b) => a.box.area.compareTo(b.box.area));
        return holding.first;
      }
    }
    Detection? best;
    var bestValue = -1.0;
    for (final v in vehicles) {
      final value =
          v.score * math.sqrt(v.box.area) * _centrality(v.box, width, height);
      if (value > bestValue) {
        bestValue = value;
        best = v;
      }
    }
    return best;
  }

  /// 1.0 at the centre of the photo, falling to 0.5 at a corner.
  static double _centrality(PixelBox box, int width, int height) {
    final dx = (box.centerX - width / 2) / (width / 2);
    final dy = (box.centerY - height / 2) / (height / 2);
    final distance = math.min(1.0, math.sqrt(dx * dx + dy * dy) / math.sqrt2);
    return 1.0 - 0.5 * distance;
  }
}

img.Image? _decodeUpright(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) return null;
  final upright = img.bakeOrientation(decoded);
  const maxSide = 1920;
  final longSide = math.max(upright.width, upright.height);
  if (longSide <= maxSide) return upright;
  final scale = maxSide / longSide;
  return img.copyResize(upright,
      width: (upright.width * scale).round(),
      height: (upright.height * scale).round());
}

List<int>? _cropAndEncode(({img.Image image, PixelBox box}) input) {
  final box = input.box.clampTo(input.image.width, input.image.height);
  final w = box.width.round();
  final h = box.height.round();
  if (w < 8 || h < 8) return null;
  var crop = img.copyCrop(input.image,
      x: box.left.round(), y: box.top.round(), width: w, height: h);
  // ML Kit reads letters best when they are at least ~30 px tall.
  const minWidth = 480;
  if (crop.width < minWidth) {
    crop = img.copyResize(crop,
        width: minWidth,
        height: (crop.height * minWidth / crop.width).round(),
        interpolation: img.Interpolation.cubic);
  }
  return img.encodeJpg(crop, quality: 92);
}
