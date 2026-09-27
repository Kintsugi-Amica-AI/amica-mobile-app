import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';
import '../utils/vision_log.dart';

/// Runs an Ultralytics YOLO (v8 / v11) detector exported to TFLite, fully
/// on the phone. Used twice: the COCO vehicle detector and the plate
/// finder trained in amica-ai-core/plate_ocr/training.
///
/// Expected model: input `[1, S, S, 3]` float32 RGB in 0-1, output
/// `[1, 4 + classes, anchors]` with `cx, cy, w, h` (input pixels or 0-1)
/// followed by per-class scores. That is what `yolo export format=onnx`
/// followed by `onnx2tf` produces (see training/export_tflite.py).
///
/// When the model asset is missing (for example the plate finder has not
/// been trained yet) [load] returns null and callers fall back to the old
/// behaviour, so a scan never gets worse because of this class.
class YoloDetector {
  YoloDetector._(this._interpreter, this.labels, this.inputSize,
      this._channels, this._anchors);

  final Interpreter _interpreter;
  final List<String> labels;
  final int inputSize;
  final int _channels;
  final int _anchors;

  static final Map<String, Future<YoloDetector?>> _cache = {};

  /// Loads (once per app run) the model at [modelAsset] with one label per
  /// line in [labelsAsset]. Returns null when either asset is missing or
  /// the model does not have the expected shape.
  static Future<YoloDetector?> load(String modelAsset, String labelsAsset) =>
      _cache.putIfAbsent(modelAsset, () => _load(modelAsset, labelsAsset));

  static Future<YoloDetector?> _load(
      String modelAsset, String labelsAsset) async {
    try {
      final labels = (await rootBundle.loadString(labelsAsset))
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      final interpreter = await Interpreter.fromAsset(modelAsset,
          options: InterpreterOptions()..threads = 2);
      final input = interpreter.getInputTensor(0).shape;
      final output = interpreter.getOutputTensor(0).shape;
      if (input.length != 4 ||
          input[1] != input[2] ||
          input[3] != 3 ||
          output.length != 3 ||
          output[1] != labels.length + 4) {
        visionLog('$modelAsset has unexpected shape $input -> $output '
            'for ${labels.length} labels - not used');
        interpreter.close();
        return null;
      }
      visionLog('loaded $modelAsset: input $input, output $output, '
          '${labels.length} labels');
      return YoloDetector._(
          interpreter, labels, input[1], output[1], output[2]);
    } catch (error) {
      visionLog('$modelAsset not available ($error)');
      return null;
    }
  }

  /// Finds objects in [image]. Boxes come back in [image] pixels.
  Future<List<Detection>> detect(
    img.Image image, {
    double minScore = 0.35,
    Set<String>? onlyLabels,
  }) async {
    final watch = Stopwatch()..start();
    final prepared = await compute(
        _letterbox, (image: image, size: inputSize));
    final prepMs = watch.elapsedMilliseconds;
    final output = Float32List(_channels * _anchors);
    _interpreter.run(prepared.input.buffer.asUint8List(), output.buffer);
    final found = decodeYoloOutput(
      output,
      channels: _channels,
      anchors: _anchors,
      labels: labels,
      inputSize: inputSize,
      scale: prepared.scale,
      padX: prepared.padX,
      padY: prepared.padY,
      imageWidth: image.width,
      imageHeight: image.height,
      minScore: minScore,
      onlyLabels: onlyLabels,
    );
    visionLog('${labels.length == 1 ? labels.first : '$_channels-channel'} '
        'model on ${image.width}x${image.height}: prepare ${prepMs}ms, '
        'total ${watch.elapsedMilliseconds}ms, '
        '${found.take(3).map((d) => '${d.label} ${d.score.toStringAsFixed(2)}').join(', ')}'
        '${found.isEmpty ? 'nothing above ${minScore.toStringAsFixed(2)}' : ''}');
    return found;
  }
}

/// Resizes [input.image] to fit a square of [input.size] keeping its
/// aspect ratio, pads with grey (114) like Ultralytics does, and returns
/// NHWC float32 RGB in 0-1.
({Float32List input, double scale, double padX, double padY}) _letterbox(
    ({img.Image image, int size}) input) {
  final image = input.image;
  final size = input.size;
  final scale = math.min(size / image.width, size / image.height);
  final w = math.max(1, (image.width * scale).round());
  final h = math.max(1, (image.height * scale).round());
  final resized = img.copyResize(image,
      width: w, height: h, interpolation: img.Interpolation.linear);
  final padX = ((size - w) / 2).floorToDouble();
  final padY = ((size - h) / 2).floorToDouble();

  final data = Float32List(size * size * 3)
    ..fillRange(0, size * size * 3, 114 / 255);
  for (var y = 0; y < h; y++) {
    final row = (y + padY.toInt()) * size;
    for (var x = 0; x < w; x++) {
      final p = resized.getPixel(x, y);
      final i = (row + x + padX.toInt()) * 3;
      data[i] = p.r / 255;
      data[i + 1] = p.g / 255;
      data[i + 2] = p.b / 255;
    }
  }
  return (input: data, scale: scale, padX: padX, padY: padY);
}

/// Turns a raw `[4 + classes, anchors]` YOLO output into boxes in the
/// original image. Public so the decoding can be unit tested without a
/// model.
List<Detection> decodeYoloOutput(
  Float32List output, {
  required int channels,
  required int anchors,
  required List<String> labels,
  required int inputSize,
  required double scale,
  required double padX,
  required double padY,
  required int imageWidth,
  required int imageHeight,
  double minScore = 0.35,
  Set<String>? onlyLabels,
}) {
  final classes = channels - 4;
  // Some exports give box coordinates in 0-1 instead of input pixels.
  var maxCoord = 0.0;
  for (var a = 0; a < anchors; a++) {
    maxCoord = math.max(maxCoord, output[2 * anchors + a]);
  }
  final coordScale = maxCoord <= 1.5 ? inputSize.toDouble() : 1.0;

  final found = <Detection>[];
  for (var a = 0; a < anchors; a++) {
    var bestClass = -1;
    var bestScore = minScore;
    for (var c = 0; c < classes; c++) {
      final score = output[(4 + c) * anchors + a];
      if (score > bestScore) {
        bestScore = score;
        bestClass = c;
      }
    }
    if (bestClass < 0) continue;
    final label = labels[bestClass];
    if (onlyLabels != null && !onlyLabels.contains(label)) continue;

    final cx = output[a] * coordScale;
    final cy = output[anchors + a] * coordScale;
    final w = output[2 * anchors + a] * coordScale;
    final h = output[3 * anchors + a] * coordScale;
    final box = PixelBox(
      (cx - w / 2 - padX) / scale,
      (cy - h / 2 - padY) / scale,
      (cx + w / 2 - padX) / scale,
      (cy + h / 2 - padY) / scale,
    ).clampTo(imageWidth, imageHeight);
    if (box.area <= 0) continue;
    found.add(Detection(label: label, score: bestScore, box: box));
  }
  return nonMaxSuppression(found);
}
