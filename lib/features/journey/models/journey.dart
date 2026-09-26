import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/journey_route_service.dart';
import '../../../services/transit_plan_service.dart';
import 'location_data_model.dart';

class Journey {
  /// Distance to the drop-off at which the Smart Stop Alert sounds.
  static const int defaultAlertDistanceMeters = 2000;

  const Journey({
    required this.id,
    required this.userId,
    required this.journeyType,
    required this.startLocation,
    required this.currentLocation,
    required this.destination,
    required this.estimatedDurationMinutes,
    required this.estimatedEndTime,
    required this.status,
    required this.safetyCheck,
    required this.stopAlert,
    required this.metadata,
    required this.schemaVersion,
    required this.createdAt,
    required this.updatedAt,
    this.actualEndTime,
    this.pause = const {},
    this.route = const {},
    this.transitPlanData = const {},
    this.liveShare = const {},
  });

  final String id;
  final String userId;
  final String journeyType;
  final LocationDataModel? startLocation;
  final LocationDataModel? currentLocation;
  final Map<String, dynamic> destination;
  final int estimatedDurationMinutes;
  final DateTime estimatedEndTime;
  final DateTime? actualEndTime;
  final String status;
  final Map<String, dynamic> safetyCheck;

  /// Smart Stop Alert settings, as sketched in the backend schema's
  /// "Smart Stop Alert can use `destination` and `journeyType`" note.
  ///
  /// Present and enabled only on rides started from the bus stop alert flow;
  /// ordinary timer journeys leave it empty.
  final Map<String, dynamic> stopAlert;
  final Map<String, dynamic> metadata;

  /// Set while the user has paused the countdown: `pausedAt`, `resumeAt` and
  /// `remainingSeconds`. Empty when the timer is running.
  ///
  /// While paused, [estimatedEndTime] is already `resumeAt + remaining`, so
  /// the native safety monitor and the backend still hold a real deadline if
  /// the user never comes back to resume.
  final Map<String, dynamic> pause;

  /// Suggested route saved when the journey started (see [JourneyRoute]).
  final Map<String, dynamic> route;

  /// Bus/train trip plan (stops to get on / off, walks to and from them),
  /// saved when a bus or train journey started. Empty otherwise.
  final Map<String, dynamic> transitPlanData;

  /// The "watch my journey live" link, written by the backend's
  /// `startJourneyShare`: `token`, `url`, `createdAt`, and `pushedAt` once
  /// the circle was told. Empty when the journey is not shared.
  final Map<String, dynamic> liveShare;
  final int schemaVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == 'active';

  /// When the current pause ends on its own, or null if never paused.
  DateTime? get pauseResumeAt => _readNullableDateTime(pause['resumeAt']);

  /// Countdown time that was left when the pause started.
  Duration get pausedRemaining {
    final seconds = pause['remainingSeconds'];
    return Duration(seconds: seconds is num ? seconds.toInt() : 0);
  }

  /// Whether the countdown is paused at [now]. A pause whose `resumeAt` has
  /// passed has ended by itself, even before anyone clears the field.
  bool isPausedAt(DateTime now) {
    final resumeAt = pauseResumeAt;
    return isActive && resumeAt != null && now.isBefore(resumeAt);
  }

  JourneyRoute? get suggestedRoute => JourneyRoute.fromMap(route);

  TransitPlan? get transitPlan => TransitPlan.fromMap(transitPlanData);

  /// The watch-live link for this journey, or null if it is not shared.
  String? get liveShareUrl {
    final url = liveShare['url'];
    return url is String && url.isNotEmpty ? url : null;
  }

  /// Whether this ride is watching the distance to a drop-off point rather
  /// than counting down a safety timer.
  bool get isStopAlertRide => stopAlert['enabled'] == true;

  /// Whether a safety countdown runs on this journey. Rides started from the
  /// stop-alert setup screen switch it off; a bus or train journey started
  /// from the journey screen has both the countdown and the stop alert.
  bool get hasSafetyTimer => safetyCheck['required'] == true;

  /// A ride that only watches the distance to a stop (no safety countdown).
  bool get isStopAlertOnly => isStopAlertRide && !hasSafetyTimer;

  /// Where the stop alarm counts down to. On a bus or train journey with a
  /// trip plan that is the stop she gets off at, which can differ from the
  /// place she is finally going to ([destinationLocation]).
  LocationDataModel? get stopAlertTarget {
    final dropOff = stopAlert['dropOff'];
    if (dropOff is Map) {
      final latitude = dropOff['latitude'];
      final longitude = dropOff['longitude'];
      if (latitude is num && longitude is num) {
        final name = dropOff['name'];
        return LocationDataModel(
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          address: name is String ? name : '',
          updatedAt: DateTime.now(),
        );
      }
    }
    return destinationLocation;
  }

  String get stopAlertTargetName {
    final dropOff = stopAlert['dropOff'];
    if (dropOff is Map) {
      final name = dropOff['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    return destinationName;
  }

  /// How many times the route was re-planned because she left it.
  int get routeChangeCount {
    final count = route['changeCount'];
    return count is num ? count.toInt() : 0;
  }

  /// When the route was last re-planned, or null if it never was.
  DateTime? get routeChangedAt => _readNullableDateTime(route['changedAt']);

  /// How close to the drop-off the alarm should sound, in metres.
  int get alertDistanceMeters {
    final distance = stopAlert['alertDistanceMeters'];
    if (distance is num && distance > 0) {
      return distance.toInt();
    }
    return defaultAlertDistanceMeters;
  }

  /// Whether the approaching-stop alarm has already sounded for this ride,
  /// so re-opening the screen does not sound it a second time.
  bool get stopAlertTriggered => stopAlert['alertedAt'] != null;

  /// How much further the road runs than the straight line to the drop-off,
  /// resolved once when the ride started.
  ///
  /// Defaults to 1 when the backend had no route data, which leaves the alarm
  /// working on straight-line distance alone.
  double get routeFactor {
    final factor = stopAlert['routeFactor'];
    if (factor is num && factor.isFinite && factor >= 1) {
      return factor.toDouble();
    }
    return 1;
  }

  /// Road distance for the whole ride when it started, or null if unknown.
  double? get routeDistanceMeters {
    final distance = stopAlert['routeDistanceMeters'];
    if (distance is num && distance.isFinite && distance > 0) {
      return distance.toDouble();
    }
    return null;
  }

  String get destinationName {
    final name = destination['name'];
    return name is String && name.isNotEmpty ? name : 'Destination';
  }

  LocationDataModel? get destinationLocation {
    final latitude = destination['latitude'];
    final longitude = destination['longitude'];
    if (latitude is! num || longitude is! num) {
      return null;
    }
    if (latitude == 0 && longitude == 0) {
      return null;
    }

    return LocationDataModel(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      address: _readString(destination['address'], destinationName),
      updatedAt: _readDateTime(destination['updatedAt']),
    );
  }

  factory Journey.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Journey.fromMap(document.data() ?? {}, document.id);
  }

  factory Journey.fromMap(Map<String, dynamic> data, String idFallback) {
    return Journey(
      id: _readString(data['id'], idFallback),
      userId: _readString(data['userId']),
      journeyType: _readString(data['journeyType'], 'walk'),
      startLocation: _readLocation(data['startLocation']),
      currentLocation: _readLocation(data['currentLocation']),
      destination: _readMap(data['destination']),
      estimatedDurationMinutes: _readInt(
        data['estimatedDurationMinutes'],
        30,
      ),
      estimatedEndTime: _readDateTime(data['estimatedEndTime']),
      actualEndTime: _readNullableDateTime(data['actualEndTime']),
      status: _readString(data['status'], 'active'),
      safetyCheck: _readMap(
        data['safetyCheck'],
        fallback: const {
          'required': true,
          'responseDeadlineSeconds': 30,
          'respondedAt': null,
        },
      ),
      stopAlert: _readMap(data['stopAlert']),
      metadata: _readMap(data['metadata']),
      pause: _readMap(data['pause']),
      route: _readMap(data['route']),
      transitPlanData: _readMap(data['transitPlan']),
      liveShare: _readMap(data['liveShare']),
      schemaVersion: _readInt(data['schemaVersion'], 1),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'journeyType': journeyType,
      'startLocation': startLocation?.toMap(),
      'currentLocation': currentLocation?.toMap(),
      'destination': destination,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedEndTime': Timestamp.fromDate(estimatedEndTime),
      'actualEndTime':
          actualEndTime == null ? null : Timestamp.fromDate(actualEndTime!),
      'status': status,
      'safetyCheck': safetyCheck,
      'stopAlert': stopAlert,
      'metadata': metadata,
      'pause': pause.isEmpty ? null : pause,
      'route': route.isEmpty ? null : route,
      'transitPlan': transitPlanData.isEmpty ? null : transitPlanData,
      'schemaVersion': schemaVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static LocationDataModel? _readLocation(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LocationDataModel.fromMap(value);
    }
    if (value is Map) {
      return LocationDataModel.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static String _readString(dynamic value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  static Map<String, dynamic> _readMap(
    dynamic value, {
    Map<String, dynamic> fallback = const {},
  }) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return Map<String, dynamic>.from(fallback);
  }

  static DateTime _readDateTime(dynamic value) {
    return _readNullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _readNullableDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
