import 'package:cloud_firestore/cloud_firestore.dart';

class LocationDataModel {
  const LocationDataModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final String address;
  final DateTime updatedAt;

  factory LocationDataModel.fromMap(Map<String, dynamic>? data) {
    final safeData = data ?? const <String, dynamic>{};
    return LocationDataModel(
      latitude: _readDouble(safeData['latitude']),
      longitude: _readDouble(safeData['longitude']),
      address: _readString(safeData['address']),
      updatedAt: _readDateTime(safeData['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static double _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  static String _readString(dynamic value) {
    return value is String ? value : '';
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
