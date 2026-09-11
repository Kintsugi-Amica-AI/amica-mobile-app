import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
    required this.isActive,
    required this.notificationMethods,
    required this.metadata,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String relationship;
  final int priority;
  final bool isActive;
  final List<String> notificationMethods;
  final Map<String, dynamic> metadata;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EmergencyContact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return EmergencyContact.fromMap(document.data() ?? {}, document.id);
  }

  factory EmergencyContact.fromMap(
    Map<String, dynamic> data,
    String idFallback,
  ) {
    return EmergencyContact(
      id: _readString(data['id'], idFallback),
      userId: _readString(data['userId']),
      name: _readString(data['name']),
      phone: _readString(data['phone'], _readString(data['phoneNumber'])),
      relationship: _readString(data['relationship']),
      priority: _readInt(data['priority'], 1),
      isActive: _readBool(data['isActive'], true),
      notificationMethods: _readStringList(
        data['notificationMethods'],
        const ['sms'],
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
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'priority': priority,
      'isActive': isActive,
      'notificationMethods': notificationMethods,
      'metadata': metadata,
      'schemaVersion': schemaVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? isActive,
    List<String>? notificationMethods,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      notificationMethods: notificationMethods ?? this.notificationMethods,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  static bool _readBool(dynamic value, bool fallback) {
    return value is bool ? value : fallback;
  }

  static List<String> _readStringList(
    dynamic value,
    List<String> fallback,
  ) {
    if (value is! List) {
      return List<String>.from(fallback);
    }

    final items = value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return items.isEmpty ? List<String>.from(fallback) : items;
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
