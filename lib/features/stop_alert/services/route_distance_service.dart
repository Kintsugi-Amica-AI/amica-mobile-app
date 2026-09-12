import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

/// How much further the road runs than the straight line between two points.
class RouteEstimate {
  const RouteEstimate({
    required this.roadDistanceMeters,
    required this.straightLineMeters,
    required this.routeFactor,
  });

  final double roadDistanceMeters;
  final double straightLineMeters;

  /// roadDistanceMeters / straightLineMeters, clamped server-side to a range
  /// the alarm trusts.
  final double routeFactor;
}

/// Looks up road distance for a bus ride, once, before the ride starts.
///
/// The alarm itself runs on-device against straight-line distance, because a
/// bus goes through tunnels and dead zones and the alarm must never depend on
/// the network. What straight-line distance cannot know is how much further
/// the road winds, so this resolves that once while the rider still has signal
/// and hands back a factor the device applies offline for the whole ride.
///
/// The lookup goes through the backend rather than calling Directions
/// directly: a web-service key cannot be restricted to an Android signature,
/// so shipping one in the app would expose a billable key.
class RouteDistanceService {
  const RouteDistanceService();

  static const Duration _timeout = Duration(seconds: 10);

  /// The road/straight-line ratio, or null when road distance is unavailable.
  ///
  /// Null is an ordinary outcome, not a failure: the backend function may not
  /// be deployed, no Directions key may be configured, or the rider may be
  /// offline. Callers fall back to straight-line distance, which is how the
  /// stop alert behaves without any route data.
  Future<RouteEstimate?> estimate({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getRouteDistance');
      // Read untyped: the decoded map comes back with different key typing on
      // different platforms, and a failed cast here would quietly disable road
      // distance rather than surface anything.
      final response = await callable.call<dynamic>({
        'originLatitude': originLatitude,
        'originLongitude': originLongitude,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
      }).timeout(_timeout);

      final data = response.data;
      if (data is! Map || data['available'] != true) {
        return null;
      }

      final routeFactor = _readDouble(data['routeFactor']);
      final roadDistanceMeters = _readDouble(data['roadDistanceMeters']);
      final straightLineMeters = _readDouble(data['straightLineMeters']);

      if (routeFactor == null ||
          roadDistanceMeters == null ||
          straightLineMeters == null ||
          routeFactor < 1) {
        return null;
      }

      return RouteEstimate(
        roadDistanceMeters: roadDistanceMeters,
        straightLineMeters: straightLineMeters,
        routeFactor: routeFactor,
      );
    } catch (_) {
      // Road distance is a refinement. A rider must still be able to start a
      // ride with no backend, no key, and no signal.
      return null;
    }
  }

  double? _readDouble(Object? value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    return null;
  }
}
