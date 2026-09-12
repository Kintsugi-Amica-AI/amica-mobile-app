import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/vehicle_status.dart';

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
  String cleanPlateText(String rawText) {
    if (rawText.isEmpty) {
      return '';
    }
    return rawText.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  /// Whether a cleaned string is actually shaped like a vehicle plate
  /// (a handful of letters and digits) rather than unrelated text ML Kit
  /// also picked up in the frame, such as a brand badge or dealer sticker.
  bool looksLikePlate(String cleaned) {
    return RegExp(r'^(?:(?:WP|CP|SP|NP|EP|NW|NC|SG|UP))?[A-Z]{2,3}[0-9]{4}$')
        .hasMatch(cleaned);
  }

  /// Province is separate from the nationally unique modern registration.
  /// Never turn letters into digits: silently guessing could identify another car.
  String canonicalPlate(String text) {
    var cleaned = cleanPlateText(text);
    if (RegExp(r'^(WP|CP|SP|NP|EP|NW|NC|SG|UP)[A-Z]{2,3}[0-9]{4}$')
        .hasMatch(cleaned)) {
      cleaned = cleaned.substring(2);
    }
    return RegExp(r'^[A-Z]{2,3}[0-9]{4}$').hasMatch(cleaned) ? cleaned : '';
  }

  String parseRecognizedText(String text) {
    // The supplied older NC example has a small D security marking between
    // its series and number. It is not part of that registration.
    final upper = text.toUpperCase().replaceAllMapped(
        RegExp(r'\bNC[\s-]+D[\s-]+(\d{4})\b'), (m) => 'NC ${m[1]}');
    final matches = RegExp(
      r'(?<![A-Z0-9])(?:(?:WP|CP|SP|NP|EP|NW|NC|SG|UP)[\s-]+)?([A-Z]{2,3})[\s-]*(\d{4})(?![A-Z0-9])',
    ).allMatches(upper).map((m) => '${m[1]}${m[2]}').toSet();
    // Two different plates in the frame require a tighter scan or manual entry.
    if (matches.length == 1) return matches.single;
    if (matches.length > 1) return '';
    return canonicalPlate(text);
  }

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

  /// Runs on-device OCR (Google ML Kit) over a captured plate photo and
  /// returns the cleaned plate text, or an empty string if nothing was
  /// confidently recognized.
  ///
  /// Sri Lankan plates split their identifier across more than one visual
  /// group: a province code (e.g. "NW") sits separately from the main
  /// series and digits (e.g. "TI-9982"), and on three-wheeler/taxi plates
  /// those two parts often stack on separate lines entirely. ML Kit
  /// reports each line individually, so evaluating lines in isolation
  /// (e.g. "TI" alone, or "9982" alone) misses the plate. This groups each
  /// recognized block's full text (ML Kit already clusters spatially close
  /// lines into one block) in addition to individual lines, then prefers
  /// whichever candidate actually looks like a plate (mix of letters and
  /// digits) over simply the longest text ML Kit found, since a vehicle's
  /// badge, dealer sticker, or background signage is often longer than the
  /// plate itself and would otherwise win by length.
  Future<String> extractPlateText(String imagePath,
      {bool tryRotations = true}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      final allCandidates = <String>[];

      // The whole image's text in natural reading order, in case the
      // province code and the main plate code are separate ML Kit blocks
      // that never get clustered together (e.g. a province box set apart
      // from the main plate face).
      final wholeImageCleaned = parseRecognizedText(result.text);
      if (wholeImageCleaned.length >= 4) {
        allCandidates.add(wholeImageCleaned);
      }

      for (final block in result.blocks) {
        final blockCleaned = parseRecognizedText(block.text);
        if (blockCleaned.length >= 4) {
          allCandidates.add(blockCleaned);
        }
        for (final line in block.lines) {
          final lineCleaned = parseRecognizedText(line.text);
          if (lineCleaned.length >= 4) {
            allCandidates.add(lineCleaned);
          }
        }
      }

      final plates = allCandidates.where(looksLikePlate).toSet();
      if (plates.length == 1) return plates.single;
      if (plates.length > 1 || !tryRotations) return '';
      // Gallery photos may be sideways without EXIF rotation metadata.
      final rotatedPlates = <String>{};
      for (final angle in [90, 180, 270]) {
        final path = '$imagePath.rotate$angle.jpg';
        try {
          final rotated = await compute(_rotatePlateImage,
              (bytes: await File(imagePath).readAsBytes(), angle: angle));
          if (rotated == null) continue;
          await File(path).writeAsBytes(rotated);
          final plate = await extractPlateText(path, tryRotations: false);
          if (plate.isNotEmpty) rotatedPlates.add(plate);
        } finally {
          if (await File(path).exists()) await File(path).delete();
        }
      }
      return rotatedPlates.length == 1 ? rotatedPlates.single : '';
    } catch (_) {
      throw const PlateScanException(
        'Could not read the plate. Try a clearer, well-lit photo.',
      );
    } finally {
      await recognizer.close();
    }
  }

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
