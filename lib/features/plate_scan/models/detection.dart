import 'dart:math' as math;

/// An axis-aligned box in image pixels.
class PixelBox {
  const PixelBox(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => math.max(0, right - left);
  double get height => math.max(0, bottom - top);
  double get area => width * height;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  PixelBox intersect(PixelBox other) => PixelBox(
        math.max(left, other.left),
        math.max(top, other.top),
        math.min(right, other.right),
        math.min(bottom, other.bottom),
      );

  double iou(PixelBox other) {
    final overlap = intersect(other).area;
    final union = area + other.area - overlap;
    return union <= 0 ? 0 : overlap / union;
  }

  bool contains(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;

  /// Grows the box by [fraction] of its size on every side.
  PixelBox inflate(double fraction) => PixelBox(
        left - width * fraction,
        top - height * fraction,
        right + width * fraction,
        bottom + height * fraction,
      );

  /// Keeps the box inside a `width` x `height` image.
  PixelBox clampTo(int imageWidth, int imageHeight) => PixelBox(
        left.clamp(0, imageWidth.toDouble()).toDouble(),
        top.clamp(0, imageHeight.toDouble()).toDouble(),
        right.clamp(0, imageWidth.toDouble()).toDouble(),
        bottom.clamp(0, imageHeight.toDouble()).toDouble(),
      );

  @override
  String toString() =>
      'PixelBox(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, '
      '${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})';
}

/// One object found by an on-device detector.
class Detection {
  const Detection({
    required this.label,
    required this.score,
    required this.box,
  });

  final String label;
  final double score;
  final PixelBox box;
}

/// Standard greedy non-maximum suppression: keeps the best box and drops
/// any other box of the same label that overlaps it by more than
/// [iouThreshold].
List<Detection> nonMaxSuppression(
  List<Detection> detections, {
  double iouThreshold = 0.45,
  int maxResults = 20,
}) {
  final sorted = [...detections]..sort((a, b) => b.score.compareTo(a.score));
  final kept = <Detection>[];
  for (final candidate in sorted) {
    final overlaps = kept.any((k) =>
        k.label == candidate.label && k.box.iou(candidate.box) > iouThreshold);
    if (!overlaps) kept.add(candidate);
    if (kept.length >= maxResults) break;
  }
  return kept;
}
