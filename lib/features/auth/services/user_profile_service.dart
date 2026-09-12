import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  const UserProfileService();

  static const String defaultSecretPhrase = 'amica help me';
  static const String defaultFakeCallContactName = 'Amica Friend';
  static const String defaultFakeCallPhoneNumber = '+94 700 000 000';
  static const String defaultVoiceSosEmergencyMessage =
      'I need help. This is my live location.';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> getSecretPhrase() async {
    return (await getSecretPhrases()).first;
  }

  Future<List<String>> getSecretPhrases() async {
    return readSecretPhrases(await _getCurrentUserData());
  }

  static List<String> readSecretPhrases(Map<String, dynamic> data) {
    final stored = data['secretPhrases'];
    final candidates = stored is List ? stored.whereType<String>() : <String>[];
    final phrases = candidates
        .map(normalizeSecretPhrase)
        .where((phrase) => phrase.isNotEmpty)
        .toSet()
        .take(10)
        .toList();
    if (phrases.isNotEmpty) return phrases;
    final legacy = data['secretPhrase'];
    final fallback = legacy is String ? normalizeSecretPhrase(legacy) : '';
    return [fallback.isEmpty ? defaultSecretPhrase : fallback];
  }

  static String normalizeSecretPhrase(String phrase) =>
      phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Map<String, dynamic>> getSafetySettings() async {
    final data = await _getCurrentUserData();
    final safetySettings = _readMap(data['safetySettings']);

    return {
      'defaultEmergencyMessage': _readString(
        safetySettings['defaultEmergencyMessage'],
        defaultVoiceSosEmergencyMessage,
      ),
      'autoSosDelaySeconds': _readInt(
        safetySettings['autoSosDelaySeconds'],
        30,
      ),
      'fakeCallContactName': _readString(
        safetySettings['fakeCallContactName'],
        defaultFakeCallContactName,
      ),
      'fakeCallPhoneNumber': _readString(
        safetySettings['fakeCallPhoneNumber'],
        defaultFakeCallPhoneNumber,
      ),
      'voiceSosEnabled': _readBool(safetySettings['voiceSosEnabled'], true),
      'secretPhraseEnabled': _readBool(
        safetySettings['secretPhraseEnabled'],
        true,
      ),
      'fakeCallVolumeShortcutEnabled': _readBool(
        safetySettings['fakeCallVolumeShortcutEnabled'],
        true,
      ),
      'voiceSosEmergencyMessage': _readString(
        safetySettings['voiceSosEmergencyMessage'],
        _readString(
          safetySettings['defaultEmergencyMessage'],
          defaultVoiceSosEmergencyMessage,
        ),
      ),
    };
  }

  Future<void> saveFakeCallVoiceSettings({
    required String secretPhrase,
    List<String>? secretPhrases,
    required String fakeCallContactName,
    required String fakeCallPhoneNumber,
    required String voiceSosEmergencyMessage,
    required bool voiceSosEnabled,
    required bool secretPhraseEnabled,
    required bool fakeCallVolumeShortcutEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const UserProfileException('Please log in before saving settings.');
    }

    final phrases = (secretPhrases ?? [secretPhrase])
        .map(normalizeSecretPhrase)
        .where((phrase) => phrase.isNotEmpty)
        .toSet()
        .toList();
    if (phrases.isEmpty ||
        phrases.length > 10 ||
        phrases.any((p) => p.length > 120)) {
      throw const UserProfileException(
          'Add 1 to 10 phrases, each at most 120 characters.');
    }
    final message = voiceSosEmergencyMessage.trim().isEmpty
        ? defaultVoiceSosEmergencyMessage
        : voiceSosEmergencyMessage.trim();

    await _firestore.collection('users').doc(user.uid).set({
      'secretPhrase': phrases.first,
      'secretPhrases': phrases,
      'safetySettings': {
        'defaultEmergencyMessage': message,
        'fakeCallContactName': fakeCallContactName.trim().isEmpty
            ? defaultFakeCallContactName
            : fakeCallContactName.trim(),
        'fakeCallPhoneNumber': fakeCallPhoneNumber.trim().isEmpty
            ? defaultFakeCallPhoneNumber
            : fakeCallPhoneNumber.trim(),
        'voiceSosEnabled': voiceSosEnabled,
        'secretPhraseEnabled': secretPhraseEnabled,
        'fakeCallVolumeShortcutEnabled': fakeCallVolumeShortcutEnabled,
        'voiceSosEmergencyMessage': message,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const {};
    }

    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      return snapshot.data() ?? const {};
    } on FirebaseException {
      return const {};
    }
  }

  String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  int _readInt(dynamic value, int fallback) {
    return value is int ? value : fallback;
  }

  bool _readBool(dynamic value, bool fallback) {
    return value is bool ? value : fallback;
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class UserProfileException implements Exception {
  const UserProfileException(this.message);

  final String message;

  @override
  String toString() => message;
}
