import '../models/vehicle_status.dart';

class PlateScanService {
  Future<String> extractPlateText(String imagePath) async {
    // TODO: Call AI OCR module or backend endpoint.
    return 'UNKNOWN';
  }

  Future<VehicleStatus> checkVehicle(String plateNumber) async {
    // TODO: Query Firebase vehicle status collection.
    return VehicleStatus(
      plateNumber: plateNumber,
      status: VehicleRiskStatus.unknown,
      notes: 'Mock response until backend integration is ready.',
    );
  }
}
