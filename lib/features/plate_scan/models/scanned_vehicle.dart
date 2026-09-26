/// Opens the plate scanner from the journey screen. The scan then hands the
/// confirmed vehicle back instead of starting a journey of its own.
class PlateScanArguments {
  const PlateScanArguments({this.returnVehicle = false});

  /// True when the caller (the journey screen) is waiting for a
  /// [ScannedVehicle] to be popped back to it.
  final bool returnVehicle;
}

/// A vehicle the rider scanned and confirmed she is travelling in.
class ScannedVehicle {
  const ScannedVehicle({required this.plate, this.boardingStatus});

  final String plate;

  /// What happened to the "boarded vehicle" text to her contacts.
  final String? boardingStatus;
}
