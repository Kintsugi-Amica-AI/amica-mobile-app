import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/journey_route_service.dart';
import '../../../services/transit_plan_service.dart';
import '../models/journey.dart';
import '../models/location_data_model.dart';

class JourneyServiceException implements Exception {
  const JourneyServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JourneyService {
  const JourneyService();

  static const String _collectionName = 'journeys';
  static const int _activeJourneyScanLimit = 10;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> startJourney({
    required LocationDataModel startLocation,
    required String destinationName,
    required int estimatedDurationMinutes,
    LocationDataModel? destinationLocation,
    String journeyType = 'walk',
    String? vehiclePlate,
    JourneyRoute? route,
    TransitPlan? transitPlan,
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();
    final now = DateTime.now();
    final estimatedEndTime = now.add(
      Duration(minutes: estimatedDurationMinutes),
    );

    final safeDestinationName = destinationName.trim();
    final safeDestination = destinationLocation ??
        LocationDataModel(
          latitude: 0,
          longitude: 0,
          address: safeDestinationName,
          updatedAt: now,
        );

    try {
      await document.set({
        'id': document.id,
        'userId': user.uid,
        'journeyType': journeyType,
        'status': 'active',
        'startLocation': startLocation.toMap(),
        'currentLocation': startLocation.toMap(),
        'destination': {
          'name': safeDestinationName,
          'address': safeDestination.address.isEmpty
              ? safeDestinationName
              : safeDestination.address,
          'latitude': safeDestination.latitude,
          'longitude': safeDestination.longitude,
          'updatedAt': Timestamp.fromDate(safeDestination.updatedAt),
        },
        'estimatedDurationMinutes': estimatedDurationMinutes,
        'estimatedEndTime': Timestamp.fromDate(estimatedEndTime),
        'actualEndTime': null,
        'safetyCheck': {
          'required': true,
          'responseDeadlineSeconds': 60,
          'respondedAt': null,
        },
        'metadata': <String, dynamic>{
          if (vehiclePlate != null) 'vehiclePlate': vehiclePlate,
        },
        // Saved so the journey screen can draw the suggested route without
        // asking the backend again, even with a weak signal on the way.
        'route': route?.toMap(),
        // Bus / train: where to get on and off, and the walks either side.
        'transitPlan': transitPlan?.toMap(),
        'pause': null,
        'schemaVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Firestore keeps the local write queued, so let the MVP flow continue.
      return document.id;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const JourneyServiceException(
          'Firebase rules blocked this journey save. Check the deployed rules and login status.',
        );
      }
      throw JourneyServiceException(
        error.message ?? 'Could not save journey. Please try again.',
      );
    }

    return document.id;
  }

  /// The newest active timer journey.
  ///
  /// Smart Stop Alert rides live in this same collection (the backend schema
  /// builds the feature on `journeyType` and `destination`), so they are
  /// filtered out here — they have no safety countdown for the timer screen to
  /// show. Use [watchActiveStopAlertRide] for those.
  Stream<Journey?> watchActiveJourney() {
    return _watchNewestActiveJourney(
      where: (journey) => !journey.isStopAlertRide,
    );
  }

  /// The newest active bus ride that is watching the distance to a drop-off.
  Stream<Journey?> watchActiveStopAlertRide() {
    return _watchNewestActiveJourney(
      where: (journey) => journey.isStopAlertRide,
    );
  }

  Stream<Journey?> _watchNewestActiveJourney({
    required bool Function(Journey journey) where,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<Journey?>.error(
        const JourneyServiceException('Please log in to view journeys.'),
      );
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        // Enough headroom to still find the newest match of each kind when a
        // timer journey and a stop alert ride are active at the same time.
        .limit(_activeJourneyScanLimit)
        .snapshots()
        .map((snapshot) {
      for (final document in snapshot.docs) {
        final journey = Journey.fromFirestore(document);
        if (where(journey)) {
          return journey;
        }
      }
      return null;
    });
  }

  Stream<Journey?> watchJourney(String journeyId) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream<Journey?>.error(
        const JourneyServiceException('Please log in to view journeys.'),
      );
    }

    return _firestore
        .collection(_collectionName)
        .doc(journeyId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data()?['userId'] != user.uid) {
        return null;
      }
      return Journey.fromFirestore(snapshot);
    });
  }

  /// Starts a bus ride that watches the distance to a drop-off point.
  ///
  /// Stored as an ordinary `journeys` document with `journeyType: 'bus'` so it
  /// reuses the collection and security rules, plus a `stopAlert` map holding
  /// the alarm settings. The safety countdown is switched off: the rider is
  /// asking to be told when the bus nears their stop, not to be asked whether
  /// they arrived by a deadline they cannot predict.
  Future<String> startStopAlertRide({
    required LocationDataModel startLocation,
    required LocationDataModel dropOffLocation,
    required String dropOffName,
    int alertDistanceMeters = Journey.defaultAlertDistanceMeters,
    double routeFactor = 1,
    double? routeDistanceMeters,
    String journeyType = 'bus',
    TransitPlan? transitPlan,
    String? finalDestinationName,
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();
    final now = DateTime.now();
    final safeDropOffName = dropOffName.trim();

    try {
      await document.set({
        'id': document.id,
        'userId': user.uid,
        'journeyType': journeyType == 'train' ? 'train' : 'bus',
        'status': 'active',
        'startLocation': startLocation.toMap(),
        'currentLocation': startLocation.toMap(),
        'destination': {
          'name': safeDropOffName,
          'address': dropOffLocation.address.isEmpty
              ? safeDropOffName
              : dropOffLocation.address,
          'latitude': dropOffLocation.latitude,
          'longitude': dropOffLocation.longitude,
          'updatedAt': Timestamp.fromDate(dropOffLocation.updatedAt),
        },
        // No timer countdown on a stop alert ride, but the fields stay present
        // so anything reading `journeys` sees a consistent document shape.
        'estimatedDurationMinutes': 0,
        'estimatedEndTime': Timestamp.fromDate(now),
        'actualEndTime': null,
        'safetyCheck': {
          'required': false,
          'responseDeadlineSeconds': 30,
          'respondedAt': null,
        },
        'stopAlert': {
          'enabled': true,
          'alertDistanceMeters': alertDistanceMeters,
          'alertedAt': null,
          // Resolved once at the start, then applied on-device for the rest of
          // the ride so the alarm never needs the network.
          'routeFactor': routeFactor,
          'routeDistanceMeters': routeDistanceMeters,
        },
        'metadata': <String, dynamic>{
          // The drop-off above is the stop to get off at; this is where she
          // is actually going after the short walk from it.
          if (finalDestinationName != null &&
              finalDestinationName.trim().isNotEmpty)
            'finalDestination': finalDestinationName.trim(),
        },
        'transitPlan': transitPlan?.toMap(),
        'schemaVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Firestore keeps the local write queued, and the alarm runs on-device,
      // so a slow network must not stop the ride from starting.
      return document.id;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const JourneyServiceException(
          'Firebase rules blocked this bus ride. Check the deployed rules and login status.',
        );
      }
      throw JourneyServiceException(
        error.message ?? 'Could not start the bus ride. Please try again.',
      );
    }

    return document.id;
  }

  /// Records that the approaching-stop alarm sounded, so re-opening the ride
  /// does not sound it again.
  Future<void> markStopAlertTriggered(String journeyId) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'stopAlert.alertedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ends a bus ride, whether the rider got off at their stop or gave up on it.
  Future<void> endStopAlertRide(String journeyId) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'status': 'safe',
      'actualEndTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markJourneySafe(String journeyId) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'status': 'safe',
      'actualEndTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'safetyCheck.respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pauses the countdown for [pauseFor].
  ///
  /// The deadline is moved to the end of the pause plus the time that was
  /// left, rather than cleared. If the user never resumes, the timer starts
  /// again on its own at `resumeAt` and every safety check still fires.
  Future<void> pauseJourney(Journey journey, Duration pauseFor) async {
    _currentUserOrThrow();
    final now = DateTime.now();
    final remaining = journey.isPausedAt(now)
        ? journey.pausedRemaining
        : journey.estimatedEndTime.difference(now);
    if (remaining <= Duration.zero) {
      throw const JourneyServiceException(
        'The timer has already run out, so it cannot be paused.',
      );
    }

    final resumeAt = now.add(pauseFor);
    await _firestore.collection(_collectionName).doc(journey.id).update({
      'pause': {
        'pausedAt': Timestamp.fromDate(now),
        'resumeAt': Timestamp.fromDate(resumeAt),
        'remainingSeconds': remaining.inSeconds,
      },
      'estimatedEndTime': Timestamp.fromDate(resumeAt.add(remaining)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ends a pause early and restarts the countdown from where it stopped.
  Future<void> resumeJourney(Journey journey) async {
    _currentUserOrThrow();
    final now = DateTime.now();
    final remaining = journey.isPausedAt(now)
        ? journey.pausedRemaining
        : journey.estimatedEndTime.difference(now);
    await _firestore.collection(_collectionName).doc(journey.id).update({
      'pause': null,
      'estimatedEndTime': Timestamp.fromDate(
        now.add(remaining.isNegative ? Duration.zero : remaining),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markJourneySos(String journeyId) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'status': 'sos',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCurrentLocation(
    String journeyId,
    LocationDataModel location,
  ) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'currentLocation': location.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  User _currentUserOrThrow() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const JourneyServiceException(
        'Please log in to manage journeys.',
      );
    }
    return user;
  }
}
