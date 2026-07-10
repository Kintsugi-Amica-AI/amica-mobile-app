import 'package:cloud_firestore/cloud_firestore.dart';

import '../../journey/models/location_data_model.dart';

class SosAlert {
  const SosAlert({
    required this.id,
    required this.userId,
    required this.triggerType,
    required this.status,
    required this.location,
    required this.message,
    required this.notifiedContacts,
    required this.evidence,
    required this.metadata,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.journeyId,
  });

  final String id;
  final String userId;
  final String? journeyId;
  final String triggerType;
  final String status;
  final LocationDataModel? location;
  final String message;
  final List<String> notifiedContacts;
  final Map<String, dynamic> evidence;
  final Map<String, dynamic> metadata;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SosAlert.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return SosAlert.fromMap(document.data() ?? {}, document.id);
  }

  factory SosAlert.fromMap(Map<String, dynamic> data, String idFallback) {
    return SosAlert(
      id: _readString(data['id'], idFallback),
      userId: _readString(data['userId']),
      journeyId: _readString(data['journeyId']).isEmpty
          ? null
          : _readString(data['journeyId']),
      triggerType: _readString(data['triggerType'], 'manual'),
      status: _readString(data['status'], 'active'),
      location: _readLocation(data['location']),
      message: _readString(
        data['message'],
        'I need help. This is my live location.',
      ),
      notifiedContacts: _readStringList(data['notifiedContacts']),
      evidence: _readMap(data['evidence']),
      metadata: _readMap(data['metadata']),
      schemaVersion: _readInt(data['schemaVersion'], 1),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      if (journeyId != null) 'journeyId': journeyId,
      'triggerType': triggerType,
      'status': status,
      'location': location?.toMap(),
      'message': message,
      'notifiedContacts': notifiedContacts,
      'evidence': evidence,
      'metadata': metadata,
      'schemaVersion': schemaVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static LocationDataModel? _readLocation(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LocationDataModel.fromMap(value);
    }
    if (value is Map) {
      return LocationDataModel.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
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
