import 'package:geolocator/geolocator.dart';

import '../features/journey/models/location_data_model.dart';

class LocationServiceException implements Exception {
  const LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService();

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> requestLocationPermission() async {
    if (!await isLocationServiceEnabled()) {
      throw const LocationServiceException(
        'Location services are turned off. Please enable location on your device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Location permission is required to start a journey.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Location permission is permanently denied. Enable it from app settings.',
      );
    }

    return true;
  }

  Future<Position> getCurrentPosition() async {
    await requestLocationPermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Live position updates for a screen that tracks movement, such as the bus
  /// stop alert.
  ///
  /// [distanceFilterMeters] keeps the stream quiet while the rider is stopped
  /// in traffic instead of emitting every GPS jitter.
  Stream<Position> watchPosition({int distanceFilterMeters = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  Future<LocationDataModel> getCurrentLocationData() async {
    final position = await getCurrentPosition();
    return LocationDataModel(
      latitude: position.latitude,
      longitude: position.longitude,
      address: '',
      updatedAt: DateTime.now(),
    );
  }
}
