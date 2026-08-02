import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/vehicle_status.dart';

class PlateScanException implements Exception {
  const PlateScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PlateScanService {
  PlateScanService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _collectionName = 'vehicles';

  final FirebaseFirestore _firestore;

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

  /// Runs on-device OCR (Google ML Kit) over a captured plate photo and
  /// returns the cleaned plate text, or an empty string if nothing was
  /// confidently recognized.
  Future<String> extractPlateText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      final candidates = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final cleaned = cleanPlateText(line.text);
          if (cleaned.length >= 4) {
            candidates.add(cleaned);
          }
        }
      }

      if (candidates.isEmpty) {
        return cleanPlateText(result.text);
      }

      candidates.sort((a, b) => b.length.compareTo(a.length));
      return candidates.first;
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
