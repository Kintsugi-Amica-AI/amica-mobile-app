import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.preferences,
    required this.safetySettings,
    required this.metadata,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.secretPhrase,
    this.phoneVerified = false,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;

  /// True once [phone] has been confirmed with an SMS code (Firebase phone
  /// auth). Changing the number clears it.
  final bool phoneVerified;
  final String? secretPhrase;
  final String role;
  final String status;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> safetySettings;
  final Map<String, dynamic> metadata;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get id => uid;

  String get displayName => name;

  factory AppUser.fromMap(Map<String, dynamic> data, String uidFallback) {
    return AppUser(
      uid: _readString(data['uid'], uidFallback),
      name: _readString(
          data['name'], _readString(data['displayName'], 'Amica User')),
      email: _readString(data['email']),
      phone: _readString(data['phone'], _readString(data['phoneNumber'])),
      phoneVerified: data['phoneVerified'] == true,
      secretPhrase: _readString(data['secretPhrase']).isEmpty
          ? null
          : _readString(data['secretPhrase']),
      role: _readString(data['role'], 'user'),
      status: _readString(data['status'], 'active'),
      preferences: _readMap(data['preferences'], defaultPreferences()),
      safetySettings: _readMap(data['safetySettings'], defaultSafetySettings()),
      metadata: _readMap(data['metadata'], const {}),
      schemaVersion: _readInt(data['schemaVersion'], 1),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  factory AppUser.fallback({
    required String uid,
    required String email,
    String name = 'Amica User',
  }) {
    final now = DateTime.now();
    return AppUser(
      uid: uid,
      name: name,
      email: email,
      phone: '',
      role: 'user',
      status: 'active',
      preferences: defaultPreferences(),
      safetySettings: defaultSafetySettings(),
      metadata: const {},
      schemaVersion: 1,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'secretPhrase': secretPhrase ?? '',
      'role': role,
      'status': status,
      'schemaVersion': schemaVersion,
      'preferences': preferences,
      'safetySettings': safetySettings,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> defaultPreferences() {
    return {
      'language': 'en',
      'notificationsEnabled': true,
      'locationSharingEnabled': true,
    };
  }

  static Map<String, dynamic> defaultSafetySettings() {
    return {
      'defaultEmergencyMessage': 'I need help. This is my live location.',
      'autoSosDelaySeconds': 30,
      'fakeCallContactName': 'Amica Friend',
      'fakeCallPhoneNumber': '+94 700 000 000',
      'voiceSosEnabled': true,
      'secretPhraseEnabled': true,
      'fakeCallVolumeShortcutEnabled': true,
      'sosAudioRecordingEnabled': true,
      'voiceSosEmergencyMessage': 'I need help. This is my live location.',
    };
  }

  /// Notes for responders (allergies, conditions…), stored under
  /// `safetySettings.medicalNotes`. Empty when not set.
  String get medicalNotes {
    final value = safetySettings['medicalNotes'];
    return value is String ? value.trim() : '';
  }

  static String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    return value is int ? value : fallback;
  }

  static Map<String, dynamic> _readMap(
    dynamic value,
    Map<String, dynamic> fallback,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return Map<String, dynamic>.from(fallback);
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
