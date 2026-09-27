import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'journey_route_service.dart';

/// A bus stop or train station on a planned trip.
class TransitStop {
  const TransitStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceMeters = 0,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Straight-line metres from where it was searched (start or destination).
  final double distanceMeters;

  LatLng get position => LatLng(latitude, longitude);

  static TransitStop? fromMap(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final lat = value['latitude'];
    final lng = value['longitude'];
    if (id is! String || lat is! num || lng is! num) return null;
    final name = value['name'];
    final distance = value['distanceMeters'];
    return TransitStop(
      id: id,
      name: name is String && name.trim().isNotEmpty ? name.trim() : 'Stop',
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      distanceMeters: distance is num ? distance.toDouble() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'distanceMeters': distanceMeters,
      };
}

/// One part of a trip: a walk, or the ride itself.
class TransitLeg {
  const TransitLeg({
    required this.isWalk,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylines,
    this.fromName = '',
    this.toName = '',
    this.lineName = '',
    this.vehicle = '',
    this.from,
    this.to,
  });

  final bool isWalk;
  final double distanceMeters;
  final int durationSeconds;
  final List<String> polylines;
  final String fromName;
  final String toName;

  /// Bus route number / train line, when known.
  final String lineName;

  /// For rides: `bus` or `train` (a train trip can start or end with a bus
  /// to the station). Empty for walks.
  final String vehicle;

  /// Where the leg starts / ends, when known.
  final LatLng? from;
  final LatLng? to;

  bool get isBus => !isWalk && vehicle == 'bus';

  List<LatLng> get points => [
        for (final encoded in polylines) ...decodePolyline(encoded),
      ];

  static TransitLeg? fromMap(Object? value) {
    if (value is! Map) return null;
    final distance = value['distanceMeters'];
    final duration = value['durationSeconds'];
    final polylines = value['polylines'];
    if (distance is! num || duration is! num || polylines is! List) {
      return null;
    }
    String s(Object? v) => v is String ? v : '';
    LatLng? p(Object? v) {
      if (v is! Map) return null;
      final lat = v['latitude'];
      final lng = v['longitude'];
      return lat is num && lng is num
          ? LatLng(lat.toDouble(), lng.toDouble())
          : null;
    }

    return TransitLeg(
      isWalk: value['kind'] == 'walk',
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toInt(),
      polylines: polylines.whereType<String>().toList(),
      fromName: s(value['fromName']),
      toName: s(value['toName']),
      lineName: s(value['lineName']),
      vehicle: s(value['vehicle']),
      from: p(value['from']),
      to: p(value['to']),
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': isWalk ? 'walk' : 'ride',
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'polylines': polylines,
        'fromName': fromName,
        'toName': toName,
        'lineName': lineName,
        'vehicle': vehicle,
        if (from != null)
          'from': {'latitude': from!.latitude, 'longitude': from!.longitude},
        if (to != null)
          'to': {'latitude': to!.latitude, 'longitude': to!.longitude},
      };
}

/// A bus or train trip: walk to the stop you get on at, ride, then walk
/// from the stop you get off at to where you are going. Many roads have no
/// stop on them, so the walks are a real part of the journey — and the
/// get-off stop, not the final address, is what the stop alarm is for.
class TransitPlan {
  const TransitPlan({
    required this.mode,
    required this.isEstimated,
    required this.boardStop,
    required this.alightStop,
    required this.legs,
    required this.distanceMeters,
    required this.durationSeconds,
    this.boardCandidates = const [],
    this.alightCandidates = const [],
  });

  /// `bus` or `train`.
  final String mode;

  /// True when Amica composed the trip from nearby stops (no timetable data
  /// for the area); false for a real timetabled route with line numbers.
  final bool isEstimated;

  final TransitStop boardStop;
  final TransitStop alightStop;

  /// Other nearby stops the rider can pick instead.
  final List<TransitStop> boardCandidates;
  final List<TransitStop> alightCandidates;

  final List<TransitLeg> legs;
  final double distanceMeters;
  final int durationSeconds;

  bool get isTrain => mode == 'train';

  /// Walking before getting on, in metres (0 when already at the stop).
  double get walkToStopMeters =>
      legs.isNotEmpty && legs.first.isWalk ? legs.first.distanceMeters : 0;

  /// Walking after getting off, in metres.
  double get walkFromStopMeters =>
      legs.length > 1 && legs.last.isWalk ? legs.last.distanceMeters : 0;

  List<LatLng> get allPoints => [for (final leg in legs) ...leg.points];

  static TransitPlan? fromMap(Object? value) {
    if (value is! Map) return null;
    final board = TransitStop.fromMap(value['boardStop']);
    final alight = TransitStop.fromMap(value['alightStop']);
    final legsRaw = value['legs'];
    final distance = value['distanceMeters'];
    final duration = value['durationSeconds'];
    if (board == null ||
        alight == null ||
        legsRaw is! List ||
        distance is! num ||
        duration is! num) {
      return null;
    }
    final legs = legsRaw.map(TransitLeg.fromMap).whereType<TransitLeg>().toList();
    if (legs.isEmpty) return null;
    List<TransitStop> stops(Object? raw) => raw is List
        ? raw.map(TransitStop.fromMap).whereType<TransitStop>().toList()
        : const [];
    return TransitPlan(
      mode: value['mode'] == 'train' ? 'train' : 'bus',
      isEstimated: value['source'] != 'transit',
      boardStop: board,
      alightStop: alight,
      boardCandidates: stops(value['boardCandidates']),
      alightCandidates: stops(value['alightCandidates']),
      legs: legs,
      distanceMeters: distance.toDouble(),
      durationSeconds: duration.toInt(),
    );
  }

  /// For saving on a journey. Candidates are left out — they only matter
  /// while choosing.
  Map<String, dynamic> toMap() => {
        'mode': mode,
        'source': isEstimated ? 'estimated' : 'transit',
        'boardStop': boardStop.toMap(),
        'alightStop': alightStop.toMap(),
        'legs': [for (final leg in legs) leg.toMap()],
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
      };
}

/// Why no plan came back — so the screen can say something useful.
enum TransitPlanUnavailable { tooClose, noStops, offline }

class TransitPlanResult {
  const TransitPlanResult.ok(TransitPlan this.plan) : unavailable = null;
  const TransitPlanResult.unavailable(TransitPlanUnavailable this.unavailable)
      : plan = null;

  final TransitPlan? plan;
  final TransitPlanUnavailable? unavailable;
}

/// Plans bus / train trips through the backend `getTransitPlan` function
/// (Google Routes + Places stay server-side, so no billable key ships in
/// the app).
class TransitPlanService {
  const TransitPlanService();

  static const Duration _timeout = Duration(seconds: 15);

  Future<TransitPlanResult> fetchPlan({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String mode,
    String? boardStopId,
    String? alightStopId,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getTransitPlan');
      final response = await callable.call<dynamic>({
        'originLatitude': originLatitude,
        'originLongitude': originLongitude,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
        'mode': mode,
        if (boardStopId != null) 'boardStopId': boardStopId,
        if (alightStopId != null) 'alightStopId': alightStopId,
      }).timeout(_timeout);

      final data = response.data;
      if (data is Map && data['available'] == true) {
        final plan = TransitPlan.fromMap(data);
        if (plan != null) return TransitPlanResult.ok(plan);
      }
      final reason = data is Map ? data['reason'] : null;
      return TransitPlanResult.unavailable(switch (reason) {
        'too-close' => TransitPlanUnavailable.tooClose,
        'no-stops' => TransitPlanUnavailable.noStops,
        _ => TransitPlanUnavailable.offline,
      });
    } catch (_) {
      return const TransitPlanResult.unavailable(
        TransitPlanUnavailable.offline,
      );
    }
  }
}
