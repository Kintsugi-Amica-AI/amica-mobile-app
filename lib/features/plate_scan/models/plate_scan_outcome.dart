import '../services/vehicle_inspector.dart';
import '../utils/vehicle_match.dart';
import 'vehicle_profile.dart';
import 'vehicle_status.dart';

/// Everything the result screen shows after one scan: the plate lookup,
/// what the camera saw of the vehicle, what the rider was told, and
/// whether they agree.
class PlateScanOutcome {
  const PlateScanOutcome({
    required this.status,
    required this.told,
    required this.inspection,
    required this.match,
  });

  factory PlateScanOutcome.evaluate({
    required VehicleStatus status,
    required VehicleExpectation told,
    required VehicleInspection inspection,
  }) =>
      PlateScanOutcome(
        status: status,
        told: told,
        inspection: inspection,
        match: VehicleMatcher.evaluate(
          told: told,
          type: inspection.type,
          colour: inspection.colour,
          community: status.community,
        ),
      );

  final VehicleStatus status;
  final VehicleExpectation told;
  final VehicleInspection inspection;
  final VehicleMatchResult match;
}
