import 'package:amica_mobile_app/features/plate_scan/models/vehicle_status.dart';
import 'package:amica_mobile_app/features/plate_scan/services/vehicle_image_service.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleStatus _status(String plate, {String? imagePath, bool demo = false}) =>
    VehicleStatus(
      plateNumber: plate,
      normalizedPlateNumber: plate,
      status: VehicleRiskStatus.unknown,
      imagePath: imagePath,
      isDemo: demo,
    );

void main() {
  test('saves the photo only for a vehicle that has none yet', () {
    expect(VehicleImageService.shouldSave(_status('CAB1234')), isTrue);
    expect(VehicleImageService.shouldSave(_status('651234')), isTrue);
    expect(
      VehicleImageService.shouldSave(
          _status('CAB1234', imagePath: 'vehicle_images/CAB1234.jpg')),
      isFalse,
    );
  });

  test('never saves for demo records or unusable plates', () {
    expect(VehicleImageService.shouldSave(_status('CAB1234', demo: true)),
        isFalse);
    expect(VehicleImageService.shouldSave(_status('')), isFalse);
    expect(VehicleImageService.shouldSave(_status('UNKNOWN')), isFalse);
  });

  test('reads the saved photo path from the vehicle document', () {
    final withImage = VehicleStatus.fromFirestore('CAB1234', {
      'image': {'path': 'vehicle_images/CAB1234.jpg'},
    });
    expect(withImage.imagePath, 'vehicle_images/CAB1234.jpg');
    expect(withImage.hasImage, isTrue);

    final without = VehicleStatus.fromFirestore('CAB1234', {'status': 'safe'});
    expect(without.hasImage, isFalse);

    final elsewhere = VehicleStatus.fromFirestore('CAB1234', {
      'image': {'path': 'somewhere/else.jpg'},
    });
    expect(elsewhere.hasImage, isFalse);
  });
}
