/// Compile-time switches for features that are built but can't run yet.
///
/// Flip a flag to `true` once its external setup is done; no other code
/// changes are needed.
class FeatureFlags {
  const FeatureFlags._();

  /// Confirm phone numbers with an SMS code (Firebase phone auth).
  ///
  /// Off for now: phone auth isn't available on the Firebase project yet.
  /// While off, the phone sheet saves the number straight to the profile
  /// with `phoneVerified: false`, and the setup checklist counts an added
  /// number as done. Turning it on restores the full SMS flow — see the
  /// console checklist on `PhoneVerificationService`.
  static const bool phoneSmsVerification = false;

  /// Scan before you ride: the AI plate finder.
  ///
  /// On: `plate_detector.tflite` is trained and bundled (test mAP50 0.985).
  /// Retrain it with `amica-ai-core/notebooks/train_plate_detector.ipynb`.
  /// Set to false to go back to reading only the scan-frame crop. If the
  /// model file is missing, the app falls back to the frame crop anyway.
  static const bool plateFinder = true;

  /// Scan before you ride: the vehicle type and colour check, the
  /// "What was I told?" picker, the match / mismatch / not sure card and
  /// community observations (`vehicle_observations`).
  ///
  /// On: `vehicle_detector_lk.tflite` (six Sri Lankan types, test mAP50
  /// 0.967, three-wheeler 0.979) and `vehicle_detector.tflite` (COCO
  /// fallback) are bundled. Community observations are saved only once the
  /// `onVehicleObservationCreated` function and Firestore rules are
  /// deployed; until then those writes are refused and silently skipped,
  /// and the type and colour check still works. Set to false to hide the
  /// whole vehicle check.
  static const bool vehicleCheck = true;
}
