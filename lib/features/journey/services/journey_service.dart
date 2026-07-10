import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> startJourney({
    required LocationDataModel startLocation,
    required String destinationName,
    required int estimatedDurationMinutes,
    String journeyType = 'walk',
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();
    final now = DateTime.now();
    final estimatedEndTime = now.add(
      Duration(minutes: estimatedDurationMinutes),
    );

    await document.set({
      'id': document.id,
      'userId': user.uid,
      'journeyType': journeyType,
      'status': 'active',
      'startLocation': startLocation.toMap(),
      'currentLocation': startLocation.toMap(),
      'destination': {
        'name': destinationName.trim(),
        'address': destinationName.trim(),
        'latitude': 0,
        'longitude': 0,
      },
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'estimatedEndTime': Timestamp.fromDate(estimatedEndTime),
      'actualEndTime': null,
      'safetyCheck': {
        'required': true,
        'responseDeadlineSeconds': 30,
        'respondedAt': null,
      },
      'metadata': const <String, dynamic>{},
      'schemaVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<Journey?> watchActiveJourney() {
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
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return Journey.fromFirestore(snapshot.docs.first);
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

  Future<void> markJourneySafe(String journeyId) async {
    _currentUserOrThrow();
    await _firestore.collection(_collectionName).doc(journeyId).update({
      'status': 'safe',
      'actualEndTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'safetyCheck.respondedAt': FieldValue.serverTimestamp(),
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
