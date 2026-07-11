import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  const UserProfileService();

  static const String defaultSecretPhrase = 'amica help me';
  static const String defaultFakeCallContactName = 'Amica Friend';
  static const String defaultFakeCallPhoneNumber = '+94 700 000 000';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> getSecretPhrase() async {
    final data = await _getCurrentUserData();
    final phrase = _readString(data['secretPhrase']).trim();
    return phrase.isEmpty ? defaultSecretPhrase : phrase;
  }

  Future<Map<String, dynamic>> getSafetySettings() async {
    final data = await _getCurrentUserData();
    final safetySettings = _readMap(data['safetySettings']);

    return {
      'defaultEmergencyMessage': _readString(
        safetySettings['defaultEmergencyMessage'],
        'I need help. This is my live location.',
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
    };
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
