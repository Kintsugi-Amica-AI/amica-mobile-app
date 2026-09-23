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
}
