import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import '../models/vehicle_status.dart';

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
    if (cleaned.length < 4 || cleaned.length > 11) {
      return false;
    }
    return RegExp(r'[A-Z]').hasMatch(cleaned) &&
        RegExp(r'[0-9]').hasMatch(cleaned);
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
      final decoded = img.decodeJpg(bytes);
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
      await File(croppedPath).writeAsBytes(img.encodeJpg(cropped, quality: 92));
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
  Future<String> extractPlateText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      final allCandidates = <String>[];

      // The whole image's text in natural reading order, in case the
      // province code and the main plate code are separate ML Kit blocks
      // that never get clustered together (e.g. a province box set apart
      // from the main plate face).
      final wholeImageCleaned = cleanPlateText(result.text);
      if (wholeImageCleaned.length >= 4) {
        allCandidates.add(wholeImageCleaned);
      }

      for (final block in result.blocks) {
        final blockCleaned = cleanPlateText(block.text);
        if (blockCleaned.length >= 4) {
          allCandidates.add(blockCleaned);
        }
        for (final line in block.lines) {
          final lineCleaned = cleanPlateText(line.text);
          if (lineCleaned.length >= 4) {
            allCandidates.add(lineCleaned);
          }
        }
      }

      final plateShaped = allCandidates.where(looksLikePlate).toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      if (plateShaped.isNotEmpty) {
        return plateShaped.first;
      }

      if (allCandidates.isEmpty) {
        return cleanPlateText(result.text);
      }

      allCandidates.sort((a, b) => b.length.compareTo(a.length));
      return allCandidates.first;
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
    final normalized = cleanPlateText(plateNumber);
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

      return VehicleStatus.fromFirestore(normalized, snapshot.docs.first.data());
    } on FirebaseException catch (error) {
      throw PlateScanException(
        error.message ?? 'Could not check vehicle status right now.',
      );
    }
  }
}
