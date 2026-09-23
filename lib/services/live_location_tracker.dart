import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Keeps a journey's `currentLocation` fresh while its live link is shared.
///
/// The watch-live page mirrors that field (via the backend), so this is what
/// makes the page move. One instance for the whole app: it outlives the
/// journey screen, and stops by itself when the journey ends.
///
/// On Android the position stream runs in a location foreground service
/// (with its own "Sharing your live location" notification), so updates keep
/// going with Amica in the background or the screen off.
class LiveLocationTracker {
  LiveLocationTracker._();

  static final LiveLocationTracker instance = LiveLocationTracker._();

  /// Never write more often than this, however fast she moves.
  static const Duration minWriteInterval = Duration(seconds: 10);

  /// Standing still still refreshes "last update" on the page this often,
  /// so a contact can tell a stationary phone from a lost one.
  static const Duration heartbeatInterval = Duration(seconds: 60);

  /// The journey being tracked, or null. Screens can listen to show state.
  final ValueNotifier<String?> activeJourneyId = ValueNotifier<String?>(null);

  StreamSubscription<Position>? _positions;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _journeyWatch;
  Timer? _heartbeat;
  DateTime? _lastWriteAt;
  Position? _lastPosition;
  Position? _pending;
  Timer? _pendingWrite;

  /// Text for the Android foreground notification, set from the UI so it is
  /// in her language.
  String notificationTitle = 'Amica is sharing your live location';
  String notificationText = 'Your circle can follow this journey.';

  bool get isTracking => activeJourneyId.value != null;

  String? _startingFor;

  /// Starts (or keeps) tracking [journeyId]. Safe to call repeatedly.
  Future<void> start(String journeyId) async {
    if ((activeJourneyId.value == journeyId && _positions != null) ||
        _startingFor == journeyId) {
      return;
    }
    _startingFor = journeyId;
    try {
      await _start(journeyId);
    } finally {
      _startingFor = null;
    }
  }

  Future<void> _start(String journeyId) async {
    await stop();

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    activeJourneyId.value = journeyId;
    _watchJourney(journeyId);
    _positions = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(
      (position) => _onPosition(journeyId, position),
      onError: (_) {/* GPS off for a moment: the heartbeat still reports. */},
    );
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      final last = _lastPosition;
      if (last != null) {
        _write(journeyId, last);
      }
    });
  }

  Future<void> stop() async {
    await _positions?.cancel();
    await _journeyWatch?.cancel();
    _heartbeat?.cancel();
    _pendingWrite?.cancel();
    _positions = null;
    _journeyWatch = null;
    _heartbeat = null;
    _pendingWrite = null;
    _pending = null;
    _lastPosition = null;
    _lastWriteAt = null;
    activeJourneyId.value = null;
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
          notificationIcon: const AndroidResource(
            name: 'ic_stat_amica',
            defType: 'drawable',
          ),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );
  }

  /// Ends tracking by itself once the journey is over, wherever it ended.
  void _watchJourney(String journeyId) {
    _journeyWatch = FirebaseFirestore.instance
        .collection('journeys')
        .doc(journeyId)
        .snapshots()
        .listen((snapshot) {
      final status = snapshot.data()?['status'];
      if (snapshot.exists && status != 'active' && status != 'sos') {
        unawaited(stop());
      }
    }, onError: (_) {});
  }

  void _onPosition(String journeyId, Position position) {
    _lastPosition = position;
    final last = _lastWriteAt;
    final now = DateTime.now();
    if (last == null || now.difference(last) >= minWriteInterval) {
      _write(journeyId, position);
      return;
    }
    // Too soon: keep only the newest and write it when allowed.
    _pending = position;
    _pendingWrite ??= Timer(minWriteInterval - now.difference(last), () {
      _pendingWrite = null;
      final pending = _pending;
      _pending = null;
      if (pending != null && activeJourneyId.value == journeyId) {
        _write(journeyId, pending);
      }
    });
  }

  void _write(String journeyId, Position position) {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }
    _lastWriteAt = DateTime.now();
    // Not awaited: Firestore queues writes offline and sends the latest
    // when the signal comes back.
    FirebaseFirestore.instance.collection('journeys').doc(journeyId).update({
      'currentLocation': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': '',
        'accuracy': position.accuracy,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }
}
