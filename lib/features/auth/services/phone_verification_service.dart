import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Why phone verification failed, in terms the UI can translate.
enum PhoneVerificationError {
  invalidNumber,
  invalidCode,
  expired,
  tooManyRequests,
  alreadyInUse,
  notEnabled,
  appNotAuthorized,
  network,
  notSignedIn,
  saveFailed,
  unknown,
}

class PhoneVerificationException implements Exception {
  const PhoneVerificationException(this.error, [this.code]);

  final PhoneVerificationError error;

  /// The raw Firebase error code, for logs and support.
  final String? code;

  @override
  String toString() => 'PhoneVerificationException($error, $code)';
}

/// Confirms a phone number with an SMS code (Firebase phone auth), links it
/// to the signed-in account, then records it on the user's Firestore
/// profile as `phone` + `phoneVerified: true`.
///
/// Firebase console requirements (one-off, per project):
/// * Authentication → Sign-in method → enable **Phone**.
/// * Project settings → Android app → add the debug and release **SHA-1 and
///   SHA-256** fingerprints (`cd android && ./gradlew signingReport`), then
///   download the new `google-services.json`.
/// * For development, add test numbers + codes under Phone → "Phone numbers
///   for testing" — they never send a real SMS.
class PhoneVerificationService {
  const PhoneVerificationService();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Turns what people actually type into E.164 (`+94771234567`), or null
  /// when it cannot be a phone number. A leading `0` is read as a Sri Lankan
  /// local number (`077 123 4567` → `+94771234567`).
  static String? normalize(String input) {
    var digits = input.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (digits.startsWith('00')) digits = '+${digits.substring(2)}';
    if (digits.startsWith('0')) digits = '+94${digits.substring(1)}';
    if (!digits.startsWith('+') && digits.startsWith('94')) {
      digits = '+$digits';
    }
    if (!digits.startsWith('+')) digits = '+94$digits';
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(digits) ? digits : null;
  }

  /// Sends (or re-sends, with [resendToken]) the SMS code.
  ///
  /// On Android the code may be read automatically; then [onAutoVerified]
  /// runs after the number has been linked and saved, and no code entry is
  /// needed.
  Future<void> sendCode({
    required String phoneE164,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function() onAutoVerified,
    required void Function(PhoneVerificationException error) onFailed,
    int? resendToken,
  }) async {
    if (_auth.currentUser == null) {
      onFailed(const PhoneVerificationException(
        PhoneVerificationError.notSignedIn,
      ));
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) async {
        try {
          await _apply(credential, phoneE164);
          onAutoVerified();
        } on PhoneVerificationException catch (error) {
          onFailed(error);
        }
      },
      verificationFailed: (error) => onFailed(_map(error)),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Checks the code the user typed and, if right, links + saves the number.
  Future<void> confirmCode({
    required String verificationId,
    required String smsCode,
    required String phoneE164,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _apply(credential, phoneE164);
  }

  Future<void> _apply(PhoneAuthCredential credential, String phone) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const PhoneVerificationException(
        PhoneVerificationError.notSignedIn,
      );
    }

    try {
      final linked = user.phoneNumber;
      if (linked == null || linked.isEmpty) {
        await user.linkWithCredential(credential);
      } else if (linked != phone) {
        await user.updatePhoneNumber(credential);
      } else {
        // Same number already on the account: re-authenticating with the
        // fresh code is what proves she still holds the phone.
        await user.reauthenticateWithCredential(credential);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'provider-already-linked') {
        try {
          await user.updatePhoneNumber(credential);
        } on FirebaseAuthException catch (inner) {
          throw _map(inner);
        }
      } else {
        throw _map(error);
      }
    }

    // Refresh the ID token so it carries the new `phone_number` claim —
    // the Firestore rules only accept `phoneVerified: true` when the saved
    // number matches that claim.
    try {
      await user.getIdToken(true);
    } catch (_) {
      // Carry on; the write below reports any real problem.
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'phone': phone,
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw PhoneVerificationException(
        PhoneVerificationError.saveFailed,
        error.code,
      );
    }
  }

  /// Saves the number on the profile without an SMS check, marked
  /// `phoneVerified: false`. Used while `FeatureFlags.phoneSmsVerification`
  /// is off; the Firestore rules accept it because it claims no
  /// verification.
  Future<void> saveUnverified(String phoneE164) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const PhoneVerificationException(
        PhoneVerificationError.notSignedIn,
      );
    }
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'phone': phoneE164,
        'phoneVerified': false,
        'phoneVerifiedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw PhoneVerificationException(
        PhoneVerificationError.saveFailed,
        error.code,
      );
    }
  }

  static PhoneVerificationException _map(FirebaseAuthException error) {
    final kind = switch (error.code) {
      'invalid-phone-number' => PhoneVerificationError.invalidNumber,
      'invalid-verification-code' ||
      'invalid-verification-id' =>
        PhoneVerificationError.invalidCode,
      'session-expired' || 'code-expired' => PhoneVerificationError.expired,
      'too-many-requests' ||
      'quota-exceeded' =>
        PhoneVerificationError.tooManyRequests,
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        PhoneVerificationError.alreadyInUse,
      'operation-not-allowed' => PhoneVerificationError.notEnabled,
      'app-not-authorized' ||
      'missing-client-identifier' ||
      'invalid-app-credential' ||
      'missing-app-credential' ||
      'captcha-check-failed' =>
        PhoneVerificationError.appNotAuthorized,
      'network-request-failed' => PhoneVerificationError.network,
      _ => PhoneVerificationError.unknown,
    };
    return PhoneVerificationException(kind, error.code);
  }
}
