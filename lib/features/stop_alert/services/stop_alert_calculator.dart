import 'dart:math' as math;

/// Distance maths and alarm decisions for the Smart Stop Alert.
///
/// Kept free of Firebase, platform channels, and widgets so the rule that
/// actually wakes someone on a bus can be unit tested directly.
class StopAlertCalculator {
  const StopAlertCalculator();

  /// Alert distances offered at setup. 2 km is the default; the shorter and
  /// longer options keep the feature usable on a few-stop city hop and on a
  /// long intercity run, where a fixed 2 km would fire immediately or far too
  /// late to be useful.
  /// The default lives on [Journey] instead, next to the field it is written
  /// to, so the alarm distance has a single definition.
  static const List<int> alertDistanceOptionsMeters = [1000, 2000, 3000, 5000];

  static const double _earthRadiusMeters = 6371000.0;

  /// Great-circle distance between two coordinates, in metres.
  double distanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final latDistance = _toRadians(endLatitude - startLatitude);
    final lonDistance = _toRadians(endLongitude - startLongitude);
    final startLat = _toRadians(startLatitude);
    final endLat = _toRadians(endLatitude);

    final a = math.sin(latDistance / 2) * math.sin(latDistance / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(lonDistance / 2) *
            math.sin(lonDistance / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Whether the approaching-stop alarm should sound right now.
  ///
  /// The alarm fires once per ride: [alreadyAlerted] keeps a bus that weaves
  /// in and out of the radius, or a GPS fix that jitters across it, from
  /// sounding repeatedly.
  bool shouldAlert({
    required double distanceMeters,
    required int alertDistanceMeters,
    required bool alreadyAlerted,
  }) {
    if (alreadyAlerted) {
      return false;
    }
    return distanceMeters <= alertDistanceMeters;
  }

  /// Whether the drop-off is already inside the alert radius when the ride is
  /// about to start, which would make the alarm sound immediately and tell the
  /// rider nothing. The setup screen warns instead of silently arming.
  bool isAlreadyWithinAlertDistance({
    required double distanceMeters,
    required int alertDistanceMeters,
  }) {
    return distanceMeters <= alertDistanceMeters;
  }

  /// How far along the ride is, from 0 at the start to 1 at the drop-off.
  ///
  /// Measured against the distance when the ride started, so the progress bar
  /// reflects this ride rather than an arbitrary scale. Returns null when
  /// there is no meaningful starting distance to measure against.
  double? progress({
    required double startDistanceMeters,
    required double currentDistanceMeters,
  }) {
    if (startDistanceMeters <= 0) {
      return null;
    }

    final travelled = startDistanceMeters - currentDistanceMeters;
    return (travelled / startDistanceMeters).clamp(0.0, 1.0);
  }

  /// Human-readable distance: metres up close, kilometres further out.
  String formatDistance(double meters) {
    if (meters.isNaN || meters < 0) {
      return 'Unknown';
    }
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final kilometers = meters / 1000;
    if (kilometers >= 100) {
      return '${kilometers.round()} km';
    }
    return '${kilometers.toStringAsFixed(1)} km';
  }

  /// Short label for an alert-distance choice, e.g. `2 km`.
  String formatAlertDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    final kilometers = meters / 1000;
    return kilometers == kilometers.roundToDouble()
        ? '${kilometers.round()} km'
        : '${kilometers.toStringAsFixed(1)} km';
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
