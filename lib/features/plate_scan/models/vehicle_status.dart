enum VehicleRiskStatus {
  safe,
  reported,
  unknown,
}

class VehicleStatus {
  const VehicleStatus({
    required this.plateNumber,
    required this.status,
    this.reportsCount = 0,
    this.riskLevel = 'unknown',
    this.notes,
  });

  final String plateNumber;
  final VehicleRiskStatus status;
  final int reportsCount;
  final String riskLevel;
  final String? notes;

  factory VehicleStatus.fromFirestore(
    String normalizedPlateNumber,
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return VehicleStatus(
        plateNumber: normalizedPlateNumber,
        status: VehicleRiskStatus.unknown,
        notes: 'No record found for this plate. Ride with caution.',
      );
    }

    return VehicleStatus(
      plateNumber: _readString(
        data['plateNumber'],
        normalizedPlateNumber,
      ),
      status: _statusFromString(data['status']),
      reportsCount: _readInt(data['reportsCount']),
      riskLevel: _readString(data['riskLevel'], 'unknown'),
      notes: _readString(data['notes']).isEmpty
          ? null
          : _readString(data['notes']),
    );
  }

  static VehicleRiskStatus _statusFromString(dynamic value) {
    return switch (value) {
      'safe' => VehicleRiskStatus.safe,
      'reported' => VehicleRiskStatus.reported,
      _ => VehicleRiskStatus.unknown,
    };
  }

  static String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
