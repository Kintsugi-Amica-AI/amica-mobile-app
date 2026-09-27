import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/detection.dart';
import '../models/vehicle_status.dart';

/// Saves the first photo of a vehicle so later riders can see what it looks
/// like, and fetches that photo for the result screen.
///
/// * Only when the plate has no photo yet (`vehicles/{plate}.image`). The
///   Storage rules allow `vehicle_images/{plate}.jpg` to be created once and
///   never replaced, so two riders scanning a new car at the same moment
///   cannot overwrite each other: the second upload is refused and ignored.
/// * Cropped to the vehicle the detector found (the whole photo when it
///   found none), at most [maxSide] px, re-encoded so no EXIF or location
///   data leaves the phone.
/// * The `onVehicleImageUploaded` Cloud Function then records the photo on
///   `vehicles/{plate}`; clients cannot write that document themselves.
class VehicleImageService {
  const VehicleImageService({FirebaseStorage? storage, FirebaseAuth? auth})
      : _storage = storage,
        _auth = auth;

  final FirebaseStorage? _storage;
  final FirebaseAuth? _auth;

  /// Longest side of a saved photo, in pixels.
  static const int maxSide = 1024;

  /// Same plates the backend accepts: letter series (CAB1234) or numeric
  /// (651234).
  static final RegExp _platePattern =
      RegExp(r'^(?:[A-Z]{2,3}[0-9]{4}|[0-9]{5,7})$');

  static String storagePath(String plate) => 'vehicle_images/$plate.jpg';

  /// Whether this scan should save the photo. Pure, so it is unit tested
  /// without Firebase.
  static bool shouldSave(VehicleStatus status) =>
      !status.hasImage &&
      !status.isDemo &&
      _platePattern.hasMatch(status.normalizedPlateNumber);

  /// Saves [image] as the first photo of [status]'s vehicle, unless it
  /// already has one. Best effort: never throws, never delays the result
  /// screen. Returns true when this upload became the vehicle's photo.
  Future<bool> saveIfFirst({
    required VehicleStatus status,
    required img.Image image,
    PixelBox? vehicleBox,
  }) async {
    try {
      if (!shouldSave(status)) return false;
      final user = (_auth ?? FirebaseAuth.instance).currentUser;
      if (user == null) return false;

      final bytes =
          await compute(_prepareJpeg, (image: image, box: vehicleBox));
      if (bytes == null) return false;

      final plate = status.normalizedPlateNumber;
      await (_storage ?? FirebaseStorage.instance)
          .ref(storagePath(plate))
          .putData(
            bytes,
            // No uploader id in the metadata: any signed-in rider can read
            // it, and who scanned which car is nobody else's business.
            SettableMetadata(
              contentType: 'image/jpeg',
              cacheControl: 'private, max-age=604800',
            ),
          )
          .timeout(const Duration(seconds: 45));
      return true;
    } on FirebaseException catch (error) {
      // 'unauthorized' here normally means another rider saved this
      // vehicle's photo first, which is exactly what we want.
      debugPrint('VehicleImageService: not saved (${error.code})');
      return false;
    } catch (error) {
      debugPrint('VehicleImageService: not saved ($error)');
      return false;
    }
  }

  /// Download URL of a saved photo, or null if it cannot be fetched.
  Future<String?> downloadUrl(String path) async {
    try {
      return await (_storage ?? FirebaseStorage.instance)
          .ref(path)
          .getDownloadURL()
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
  }
}

/// Crops to the vehicle (with a little room around it), shrinks, and
/// encodes a JPEG with no metadata. Runs in an isolate.
Uint8List? _prepareJpeg(({img.Image image, PixelBox? box}) input) {
  var photo = input.image;
  final box = input.box;
  if (box != null) {
    final area = box
        .inflate(0.08)
        .clampTo(photo.width, photo.height);
    final w = area.width.round();
    final h = area.height.round();
    // A tiny box is a bad detection: keep the whole photo instead.
    if (w >= 160 && h >= 120) {
      photo = img.copyCrop(photo,
          x: area.left.round(), y: area.top.round(), width: w, height: h);
    }
  }
  final longSide = math.max(photo.width, photo.height);
  if (longSide > VehicleImageService.maxSide) {
    final scale = VehicleImageService.maxSide / longSide;
    photo = img.copyResize(photo,
        width: (photo.width * scale).round(),
        height: (photo.height * scale).round(),
        interpolation: img.Interpolation.average);
  } else if (identical(photo, input.image)) {
    // Never touch the caller's image when stripping metadata below.
    photo = img.Image.from(photo);
  }
  // No EXIF (camera model, time, GPS) in what leaves the phone.
  photo.exif = img.ExifData();
  return img.encodeJpg(photo, quality: 82);
}
