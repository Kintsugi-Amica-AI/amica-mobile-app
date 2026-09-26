import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/journey_route_service.dart';
import '../../sos/services/circle_alert_service.dart';
import '../models/journey.dart';
import 'journey_service.dart';

/// Distance from a point to a route line, without any map or network code so
/// it can be tested on its own.
class RouteGeometry {
  const RouteGeometry._();

  static const double _metresPerDegreeLatitude = 110540;
  static const double _metresPerDegreeLongitude = 111320;

  /// The shortest distance in metres from ([latitude], [longitude]) to the
  /// line joining [points]. Infinity when there are fewer than two points.
  static double distanceToRouteMeters(
    double latitude,
    double longitude,
    List<LatLng> points,
  ) {
    if (points.length < 2) return double.infinity;
    final cosLat = math.cos(latitude * math.pi / 180);
    // A flat plane centred on the rider is accurate to well under a metre
    // over the distances that matter here.
    double x(double lng) => (lng - longitude) * _metresPerDegreeLongitude * cosLat;
    double y(double lat) => (lat - latitude) * _metresPerDegreeLatitude;

    var best = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final ax = x(points[i].longitude);
      final ay = y(points[i].latitude);
      final bx = x(points[i + 1].longitude);
      final by = y(points[i + 1].latitude);
      final dx = bx - ax;
      final dy = by - ay;
      final lengthSquared = dx * dx + dy * dy;
      // Distance from the origin (the rider) to segment a-b.
      final t = lengthSquared == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
      final px = ax + t * dx;
      final py = ay + t * dy;
      final distance = math.sqrt(px * px + py * py);
      if (distance < best) best = distance;
    }
    return best;
  }

  /// Straight-line distance in metres between two coordinates.
  static double metresBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final cosLat = math.cos(lat1 * math.pi / 180);
    final dx = (lng2 - lng1) * _metresPerDegreeLongitude * cosLat;
    final dy = (lat2 - lat1) * _metresPerDegreeLatitude;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// What happened when the journey's route changed.
class RouteChangeResult {
  const RouteChangeResult({
    required this.route,
    required this.contactsNotified,
    required this.contactsFailed,
  });

  /// The new route, already saved on the journey.
  final JourneyRoute route;
  final int contactsNotified;
  final int contactsFailed;

  bool get contactsWereTold => contactsNotified > 0;
}

/// Notices when she has left the planned route, plans a new one, saves it on
/// the journey and texts her emergency contacts that the route has changed.
///
/// Fed with her position by the journey screen. It only reacts to a real
/// departure — off the route for a while, by a clear margin, with a usable
/// GPS fix — so a wobbly fix or a short detour around a parked truck does
/// not text anyone.
class RouteChangeMonitor {
  RouteChangeMonitor({
    this.routeService = const JourneyRouteService(),
    this.journeyService = const JourneyService(),
    this.circleService = const CircleAlertService(),
  });

  final JourneyRouteService routeService;
  final JourneyService journeyService;
  final CircleAlertService circleService;

  /// How far from the route counts as having left it.
  static const double walkThresholdMeters = 120;
  static const double vehicleThresholdMeters = 250;

  /// How long she has to stay off the route before it counts.
  static const Duration offRouteFor = Duration(seconds: 40);

  /// Never re-plan (or text) more often than this.
  static const Duration minGap = Duration(minutes: 3);

  /// A hard stop so a journey through a bad GPS area cannot text her circle
  /// over and over.
  static const int maxChangesPerJourney = 5;

  /// A fix worse than this says nothing reliable about where she is.
  static const double maxAccuracyMeters = 80;

  /// Close to the destination she is arriving, not leaving the route.
  static const double arrivalRadiusMeters = 300;

  DateTime? _offRouteSince;
  DateTime? _blockedUntil;
  bool _busy = false;
  String? _journeyId;

  /// Forgets any partly-timed departure, e.g. when the journey changes.
  void reset() {
    _offRouteSince = null;
    _blockedUntil = null;
    _busy = false;
    _journeyId = null;
  }

  /// Looks at one position. Returns the result when the route changed, and
  /// null otherwise (the usual case).
  Future<RouteChangeResult?> onPosition({
    required Journey journey,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required AppLocalizations loc,
    DateTime? now,
  }) async {
    if (_journeyId != journey.id) {
      reset();
      _journeyId = journey.id;
    }
    if (!journey.isActive || _busy) return null;
    if (accuracyMeters != null && accuracyMeters > maxAccuracyMeters) {
      return null;
    }
    if (journey.routeChangeCount >= maxChangesPerJourney) return null;

    final route = journey.suggestedRoute;
    final destination = journey.destinationLocation;
    if (route == null || destination == null) return null;
    final points = route.points;
    if (points.length < 2) return null;

    final current = now ?? DateTime.now();
    if (RouteGeometry.metresBetween(
            latitude, longitude, destination.latitude, destination.longitude) <
        arrivalRadiusMeters) {
      _offRouteSince = null;
      return null;
    }

    final threshold = journey.journeyType == 'walk'
        ? walkThresholdMeters
        : vehicleThresholdMeters;
    final offBy =
        RouteGeometry.distanceToRouteMeters(latitude, longitude, points);
    if (offBy <= threshold) {
      _offRouteSince = null;
      return null;
    }

    _offRouteSince ??= current;
    if (current.difference(_offRouteSince!) < offRouteFor) return null;
    final blockedUntil = _blockedUntil;
    if (blockedUntil != null && current.isBefore(blockedUntil)) return null;

    _busy = true;
    try {
      final newRoute = await routeService.fetchRoute(
        originLatitude: latitude,
        originLongitude: longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        mode: routeModeForJourneyType(journey.journeyType),
      );
      if (newRoute == null) {
        // No route service right now: try again in a little while.
        _blockedUntil = current.add(const Duration(minutes: 1));
        return null;
      }

      await journeyService.updateRoute(
        journey.id,
        newRoute,
        changeCount: journey.routeChangeCount + 1,
      );
      _offRouteSince = null;
      _blockedUntil = current.add(minGap);

      final delivery = await _tellContacts(
        journey: journey,
        route: newRoute,
        loc: loc,
      );
      return RouteChangeResult(
        route: newRoute,
        contactsNotified: delivery.$1,
        contactsFailed: delivery.$2,
      );
    } catch (_) {
      _blockedUntil = current.add(const Duration(minutes: 1));
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Texts every active contact. Returns (reached, not reached).
  Future<(int, int)> _tellContacts({
    required Journey journey,
    required JourneyRoute route,
    required AppLocalizations loc,
  }) async {
    try {
      final guardians = await circleService.activeGuardians();
      if (guardians.isEmpty) return (0, 0);
      final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
      var message = loc.routeChangeSms(
        first.isEmpty ? loc.routeChangeSmsFallbackName : first,
        journey.destinationName,
        formatDistance(route.distanceMeters),
        (route.durationSeconds / 60).ceil(),
      );
      final url = journey.liveShareUrl;
      if (url != null) {
        message = '$message ${loc.liveShareEmergencyLine(url)}';
      }
      final results = await circleService.sendToCircle(
        guardians: guardians,
        message: message,
      );
      final reached = results.where((r) => r.reached).length;
      return (reached, results.length - reached);
    } catch (_) {
      return (0, 1);
    }
  }
}
