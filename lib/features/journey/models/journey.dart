import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_data_model.dart';

class Journey {
  const Journey({
    required this.id,
    required this.userId,
    required this.journeyType,
    required this.startLocation,
    required this.currentLocation,
    required this.destination,
    required this.estimatedDurationMinutes,
    required this.estimatedEndTime,
    required this.status,
    required this.safetyCheck,
    required this.metadata,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.actualEndTime,
  });

  final String id;
  final String userId;
  final String journeyType;
  final LocationDataModel? startLocation;
  final LocationDataModel? currentLocation;
  final Map<String, dynamic> destination;
  final int estimatedDurationMinutes;
  final DateTime estimatedEndTime;
  final DateTime? actualEndTime;
  final String status;
  final Map<String, dynamic> safetyCheck;
  final Map<String, dynamic> metadata;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';

  String get destinationName {
    final name = destination['name'];
    return name is String && name.isNotEmpty ? name : 'Destination';
  }

  factory Journey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Journey.fromMap(document.data() ?? {}, document.id);
  }

  factory Journey.fromMap(Map<String, dynamic> data, String idFallback) {
    return Journey(
      id: _readString(data['id'], idFallback),
      userId: _readString(data['userId']),
      journeyType: _readString(data['journeyType'], 'walk'),
      startLocation: _readLocation(data['startLocation']),
      currentLocation: _readLocation(data['currentLocation']),
      destination: _readMap(data['destination']),
      estimatedDurationMinutes: _readInt(
        data['estimatedDurationMinutes'],
        30,
      ),
      estimatedEndTime: _readDateTime(data['estimatedEndTime']),
      actualEndTime: _readNullableDateTime(data['actualEndTime']),
      status: _readString(data['status'], 'active'),
      safetyCheck: _readMap(
        data['safetyCheck'],
        fallback: const {
          'required': true,
          'responseDeadlineSeconds': 30,
          'respondedAt': null,
        },
      ),
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
      'journeyType': journeyType,
      'startLocation': startLocation?.toMap(),
      'currentLocation': currentLocation?.toMap(),
      'destination': destination,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedEndTime': Timestamp.fromDate(estimatedEndTime),
      'actualEndTime':
          actualEndTime == null ? null : Timestamp.fromDate(actualEndTime!),
      'status': status,
      'safetyCheck': safetyCheck,
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

  static Map<String, dynamic> _readMap(
    dynamic value, {
    Map<String, dynamic> fallback = const {},
  }) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return Map<String, dynamic>.from(fallback);
  }

  static DateTime _readDateTime(dynamic value) {
    return _readNullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _readNullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
