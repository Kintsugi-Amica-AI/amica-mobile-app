import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/vehicle_status.dart';
import '../utils/sri_lanka_plate.dart';

List<int> _encodePlateCrop(img.Image image) =>
    img.encodeJpg(image, quality: 92);

List<int>? _rotatePlateImage(({List<int> bytes, int angle}) input) {
  final decoded = img.decodeImage(Uint8List.fromList(input.bytes));
  if (decoded == null) return null;
  return img.encodeJpg(
      img.copyRotate(img.bakeOrientation(decoded), angle: input.angle));
}

class PlateScanException implements Exception {
  const PlateScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Outcome of reading one plate photo.
class PlateRead {
  const PlateRead({this.plate = '', this.suggestion = ''});

  /// The exactly-read, canonical plate, or '' when none was read.
  final String plate;

  /// A best guess to pre-fill for confirmation when [plate] is empty.
  final String suggestion;

  bool get found => plate.isNotEmpty;
}

class PlateScanService {
  const PlateScanService({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  static const String _collectionName = 'vehicles';

  final FirebaseFirestore? _injectedFirestore;

  /// Resolved lazily, matching the other Amica services, so the plate text
  /// normalization rules can be unit tested without a Firebase app.
  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  /// Normalizes raw OCR text into an uppercase alphanumeric plate string.
  ///
  /// Mirrors `clean_plate_text` in amica-ai-core's plate_ocr module so the
  /// mobile app and the AI prototype agree on the same plate format.
  String cleanPlateText(String rawText) => SriLankaPlate.clean(rawText);

  /// Whether a cleaned string is shaped like a Sri Lankan registration
  /// (see [SriLankaPlate]) rather than unrelated text ML Kit also picked
  /// up in the frame, such as a brand badge or dealer sticker.
  bool looksLikePlate(String cleaned) => SriLankaPlate.isPlateShaped(cleaned);

  /// Province is separate from the nationally unique registration.
  /// Never turn letters into digits: silently guessing could identify
  /// another car.
  String canonicalPlate(String text) => SriLankaPlate.canonical(text);

  /// The single registration read exactly from [text], or '' if none or
  /// more than one.
  String parseRecognizedText(String text) => SriLankaPlate.parse(text);

  /// Crops [imagePath] down to a fractional region (each value 0.0-1.0,
  /// relative to the orientation-corrected image) and writes the result to
  /// a new temporary JPEG, returning its path.
  ///
  /// Used so OCR only ever looks at what the on-screen scan frame actually
  /// covers, instead of the whole camera frame — background text (other
  /// signage, unrelated objects) outside the frame is cropped away before
  /// it ever reaches ML Kit. Falls back to the original path if cropping
  /// fails for any reason, so a scan never hard-fails just because of this
  /// extra step.
  Future<String> cropToFractionalRegion(
    String imagePath, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = await compute(img.decodeJpg, bytes);
      if (decoded == null) {
        return imagePath;
      }

      final oriented = img.bakeOrientation(decoded);

      final cropWidth = (width * oriented.width).round();
      final cropHeight = (height * oriented.height).round();
      if (cropWidth <= 0 || cropHeight <= 0) {
        return imagePath;
      }

      final cropX = (left * oriented.width).round().clamp(
            0,
            oriented.width - 1,
          );
      final cropY = (top * oriented.height).round().clamp(
            0,
            oriented.height - 1,
          );

      final cropped = img.copyCrop(
        oriented,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      final croppedPath =
          '$imagePath.cropped.${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(croppedPath)
          .writeAsBytes(await compute(_encodePlateCrop, cropped));
      return croppedPath;
    } catch (_) {
      return imagePath;
    }
  }

  /// Runs on-device OCR (Google ML Kit) over a plate photo.
  ///
  /// Sri Lankan plates split their registration across several visual
  /// groups (province code, series, number), and three-wheeler plates
  /// stack them on separate lines. ML Kit reports each line on its own,
  /// so the whole-image text, every block and every line are all parsed,
  /// and the single plate found across them wins.
  ///
  /// [PlateRead.plate] is only set for an exact read. When nothing reads
  /// exactly, [PlateRead.suggestion] carries a best guess with OCR
  /// look-alikes fixed (O/0, B/8, I/1...) for the officer to confirm.
  Future<PlateRead> readPlate(String imagePath,
      {bool tryRotations = true}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));
      final fragments = <String>[
        result.text,
        for (final block in result.blocks) ...[
          block.text,
          for (final line in block.lines) line.text,
        ],
      ];

      final plate = SriLankaPlate.parseFragments(fragments);
      if (plate.isNotEmpty) return PlateRead(plate: plate);
      final suggestion = SriLankaPlate.suggest(fragments);
      if (suggestion.isNotEmpty || !tryRotations) {
        return PlateRead(suggestion: suggestion);
      }

      // Gallery photos may be sideways without EXIF rotation metadata.
      final rotatedPlates = <String>{};
      var rotatedSuggestion = '';
      for (final angle in [90, 180, 270]) {
        final path = '$imagePath.rotate$angle.jpg';
        try {
          final rotated = await compute(_rotatePlateImage,
              (bytes: await File(imagePath).readAsBytes(), angle: angle));
          if (rotated == null) continue;
          await File(path).writeAsBytes(rotated);
          final read = await readPlate(path, tryRotations: false);
          if (read.found) rotatedPlates.add(read.plate);
          if (rotatedSuggestion.isEmpty) rotatedSuggestion = read.suggestion;
        } finally {
          if (await File(path).exists()) await File(path).delete();
        }
      }
      if (rotatedPlates.length == 1) {
        return PlateRead(plate: rotatedPlates.single);
      }
      return PlateRead(suggestion: rotatedSuggestion);
    } catch (_) {
      throw const PlateScanException(
        'Could not read the plate. Try a clearer, well-lit photo.',
      );
    } finally {
      await recognizer.close();
    }
  }

  /// The exactly-read plate in [imagePath], or '' if there is none.
  Future<String> extractPlateText(String imagePath,
          {bool tryRotations = true}) async =>
      (await readPlate(imagePath, tryRotations: tryRotations)).plate;

  /// Looks up a cleaned plate number against the shared Firestore
  /// `vehicles` collection (matching amica-cloud-backend's schema).
  Future<VehicleStatus> checkVehicle(String plateNumber) async {
    final normalized = canonicalPlate(plateNumber);
    if (normalized.isEmpty) {
      return const VehicleStatus(
        plateNumber: '',
        status: VehicleRiskStatus.unknown,
        notes: 'No plate text was detected. Try scanning again.',
      );
    }

    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('normalizedPlateNumber', isEqualTo: normalized)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return VehicleStatus.fromFirestore(normalized, null);
      }

      return VehicleStatus.fromFirestore(
          normalized, snapshot.docs.first.data());
    } on FirebaseException catch (error) {
      throw PlateScanException(
        error.message ?? 'Could not check vehicle status right now.',
      );
    }
  }
}
