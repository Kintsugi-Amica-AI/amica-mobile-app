import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A suggested route for a Walk/Ride with me journey.
class JourneyRoute {
  const JourneyRoute({
    required this.mode,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    this.summary = '',
  });

  /// `walking` or `driving`.
  final String mode;
  final double distanceMeters;

  /// Directions' own travel-time prediction, before any safety buffer.
  final int durationSeconds;

  /// Google encoded polyline for the whole route.
  final String polyline;
  final String summary;

  List<LatLng> get points => decodePolyline(polyline);

  /// Reads a route saved on a journey document, or null if it is missing or
  /// malformed.
  static JourneyRoute? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final polyline = value['polyline'];
    final distance = value['distanceMeters'];
    final duration = value['durationSeconds'];
    if (polyline is! String ||
        polyline.isEmpty ||
        distance is! num ||
        duration is! num ||
        distance <= 0 ||
        duration <= 0) {
      return null;
    }
    final mode = value['mode'];
    final summary = value['summary'];
    return JourneyRoute(
      mode: mode is String ? mode : 'walking',
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toInt(),
      polyline: polyline,
      summary: summary is String ? summary : '',
    );
  }

  Map<String, dynamic> toMap() => {
        'mode': mode,
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'polyline': polyline,
        'summary': summary,
      };
}

/// "850 m" under a kilometre, "2.3 km" above it.
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Travel mode Directions should use for a journey type. Buses and trains use
/// the road route: Directions transit needs a departure time and has patchy
/// coverage in Sri Lanka.
String routeModeForJourneyType(String journeyType) {
  return journeyType == 'walk' ? 'walking' : 'driving';
}

/// Decodes a Google encoded polyline into map points.
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  int? readValue() {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      if (index >= encoded.length) {
        return null;
      }
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    final dLat = readValue();
    final dLng = readValue();
    if (dLat == null || dLng == null) {
      break;
    }
    latitude += dLat;
    longitude += dLng;
    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }
  return points;
}

/// Fetches a suggested route through the backend `getJourneyRoute` function.
///
/// Goes through the backend for the same reason as the stop alert's road
/// distance: a Directions web-service key cannot be locked to the Android
/// app, so it must not ship in the APK.
class JourneyRouteService {
  const JourneyRouteService();

  static const Duration _timeout = Duration(seconds: 10);

  /// The suggested route, or null when none is available (function not
  /// deployed, no key, offline, or no route found). Callers fall back to a
  /// straight-line estimate.
  Future<JourneyRoute?> fetchRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    String mode = 'walking',
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getJourneyRoute');
      final response = await callable.call<dynamic>({
        'originLatitude': originLatitude,
        'originLongitude': originLongitude,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
        'mode': mode,
      }).timeout(_timeout);

      final data = response.data;
      if (data is! Map || data['available'] != true) {
        debugPrint('getJourneyRoute: backend returned no route ($data)');
        return null;
      }
      return JourneyRoute.fromMap(data);
    } catch (error) {
      // Surfaces the real cause (not-found = function not deployed,
      // unauthenticated = not signed in, timeout, etc.) in `flutter run` logs.
      debugPrint('getJourneyRoute failed: $error');
      return null;
    }
  }
}
