import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../models/detection.dart';
import '../models/vehicle_profile.dart';

/// Finds a vehicle's main body colour from a photo. No AI: pixels from the
/// body panel around the plate are sorted into named colours and the
/// biggest group wins.
///
/// Pure Dart (package:image only) so it runs inside `compute` and in unit
/// tests. amica-ai-core/plate_ocr/src/vehicle_colour.py mirrors these
/// thresholds; keep the two in step.
class VehicleColourClassifier {
  const VehicleColourClassifier._();

  /// Mean scene brightness (0-255) below which colours are not trusted.
  static const double lowLightLuma = 55;

  /// A dim scene where most of the frame (road, walls, paint) turns
  /// orange-amber is lit by sodium / warm street lights. A red car close
  /// up does not trip this: red sits outside the amber hue band.
  static const double warmCastShare = 0.55;
  static const double warmCastMaxLuma = 115;

  /// The winning colour must hold at least this share of body pixels.
  static const double minShare = 0.35;

  /// Samples per side of the body region; keeps this fast on a phone.
  static const int _grid = 48;

  static VehicleColourReading classify(
    img.Image image, {
    PixelBox? plate,
    PixelBox? vehicle,
  }) {
    final scene = _sceneStats(image);
    final lowLight = scene.luma < lowLightLuma;
    final colourCast =
        scene.luma < warmCastMaxLuma && scene.amberShare >= warmCastShare;

    final region = bodyRegion(image.width, image.height,
        plate: plate, vehicle: vehicle);
    if (region == null || region.width < 4 || region.height < 4) {
      return VehicleColourReading(
          colour: null, share: 0, lowLight: lowLight, colourCast: colourCast);
    }

    final skip = plate?.inflate(0.15);
    final votes = <VehicleColour, int>{};
    var total = 0;
    for (var gy = 0; gy < _grid; gy++) {
      final y = region.top + (gy + 0.5) * region.height / _grid;
      for (var gx = 0; gx < _grid; gx++) {
        final x = region.left + (gx + 0.5) * region.width / _grid;
        if (skip != null && skip.contains(x, y)) continue;
        final p = image.getPixel(x.floor(), y.floor());
        final colour = classifyPixel(p.r.toInt(), p.g.toInt(), p.b.toInt());
        votes[colour] = (votes[colour] ?? 0) + 1;
        total++;
      }
    }
    if (total < 30) {
      return VehicleColourReading(
          colour: null, share: 0, lowLight: lowLight, colourCast: colourCast);
    }

    final best = votes.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final share = best.value / total;
    return VehicleColourReading(
      colour: share >= minShare ? best.key : null,
      share: share,
      lowLight: lowLight,
      colourCast: colourCast,
    );
  }

  /// The patch of body paint to sample.
  ///
  /// With a plate: the panel around and above it (boot lid, tailgate or
  /// bonnet front), one plate-width to each side and a little over two
  /// plate-heights up, which stays clear of the windscreen, road and
  /// tyres. Without a plate: the middle band of the vehicle box.
  static PixelBox? bodyRegion(
    int width,
    int height, {
    PixelBox? plate,
    PixelBox? vehicle,
  }) {
    PixelBox? region;
    if (plate != null && plate.area > 0) {
      region = PixelBox(
        plate.left - plate.width,
        plate.top - plate.height * 2.2,
        plate.right + plate.width,
        plate.bottom + plate.height * 0.3,
      );
      if (vehicle != null) region = region.intersect(vehicle);
    } else if (vehicle != null && vehicle.area > 0) {
      region = PixelBox(
        vehicle.left + vehicle.width * 0.15,
        vehicle.top + vehicle.height * 0.35,
        vehicle.right - vehicle.width * 0.15,
        vehicle.top + vehicle.height * 0.75,
      );
    }
    if (region == null) return null;
    final clamped = region.clampTo(width, height);
    return clamped.area > 0 ? clamped : null;
  }

  /// Names the colour of one pixel (0-255 channels).
  static VehicleColour classifyPixel(int r, int g, int b) {
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final v = maxC / 255;
    final chroma = maxC - minC;
    final s = maxC == 0 ? 0.0 : chroma / maxC;

    if (v < 0.18) return VehicleColour.black;
    if (s < 0.20 || chroma < 28) {
      if (v >= 0.80) return VehicleColour.white;
      if (v >= 0.55) return VehicleColour.silver;
      if (v >= 0.30) return VehicleColour.grey;
      return VehicleColour.black;
    }

    final h = hue(r, g, b);
    if (h < 12 || h >= 330) {
      return v < 0.45 ? VehicleColour.maroon : VehicleColour.red;
    }
    if (h < 40) return v < 0.55 ? VehicleColour.brown : VehicleColour.orange;
    if (h < 70) return v < 0.50 ? VehicleColour.brown : VehicleColour.yellow;
    if (h < 165) return VehicleColour.green;
    if (h < 290) return VehicleColour.blue;
    return VehicleColour.maroon;
  }

  /// Hue in degrees, 0-360.
  static double hue(int r, int g, int b) {
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final d = (maxC - minC).toDouble();
    if (d == 0) return 0;
    double h;
    if (maxC == r) {
      h = ((g - b) / d) % 6;
    } else if (maxC == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    h *= 60;
    return h < 0 ? h + 360 : h;
  }

  /// Mean brightness of the whole photo, and the share of its pixels
  /// that are tinted amber (hue 15-50 degrees, clearly saturated).
  static ({double luma, double amberShare}) _sceneStats(img.Image image) {
    const n = 32;
    var luma = 0.0;
    var amber = 0;
    for (var gy = 0; gy < n; gy++) {
      final y = ((gy + 0.5) * image.height / n).floor();
      for (var gx = 0; gx < n; gx++) {
        final x = ((gx + 0.5) * image.width / n).floor();
        final p = image.getPixel(x, y);
        final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
        luma += 0.299 * r + 0.587 * g + 0.114 * b;
        if (isAmber(r, g, b)) amber++;
      }
    }
    const count = n * n;
    return (luma: luma / count, amberShare: amber / count);
  }

  static bool isAmber(int r, int g, int b) {
    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    if (maxC < 25) return false;
    final s = (maxC - minC) / maxC;
    final h = hue(r, g, b);
    return s >= 0.30 && h >= 15 && h < 50;
  }
}
