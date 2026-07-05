enum VehicleRiskStatus {
  safe,
  reported,
  unknown,
}

class VehicleStatus {
  const VehicleStatus({
    required this.plateNumber,
    required this.status,
    this.notes,
  });

  final String plateNumber;
  final VehicleRiskStatus status;
  final String? notes;
}
