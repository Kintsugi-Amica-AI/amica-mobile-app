import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../journey/models/location_data_model.dart';

class SosServiceException implements Exception {
  const SosServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SosService {
  const SosService();

  static const String _collectionName = 'sos_alerts';
  static const String _defaultMessage =
      'I need help. This is my live location.';

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> createManualSosAlert({
    required LocationDataModel location,
    String? journeyId,
  }) {
    return _createSosAlert(
      triggerType: 'manual',
      location: location,
      journeyId: journeyId,
    );
  }

  Future<String> createTimerSosAlert({
    required LocationDataModel location,
    required String journeyId,
  }) {
    return _createSosAlert(
      triggerType: 'timer',
      location: location,
      journeyId: journeyId,
    );
  }

  Future<String> createVoiceSosAlert({
    required LocationDataModel location,
    required String detectedPhrase,
    required String expectedPhrase,
    double? confidenceScore,
    String? journeyId,
  }) {
    return _createSosAlert(
      triggerType: 'voice',
      location: location,
      journeyId: journeyId,
      evidence: {
        'voicePhraseDetected': true,
        'detectedPhrase': detectedPhrase,
        'expectedPhrase': expectedPhrase,
        'voiceConfidenceScore': confidenceScore ?? 0,
        'fakeCallActive': true,
      },
    );
  }

  Future<String> _createSosAlert({
    required String triggerType,
    required LocationDataModel location,
    String? journeyId,
    Map<String, dynamic> evidence = const <String, dynamic>{},
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();

    try {
      await document.set({
        'id': document.id,
        'userId': user.uid,
        if (journeyId != null) 'journeyId': journeyId,
        'triggerType': triggerType,
        'status': 'active',
        'location': location.toMap(),
        'message': _defaultMessage,
        'notifiedContacts': const <String>[],
        'evidence': evidence,
        'metadata': const <String, dynamic>{},
        'schemaVersion': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Firestore keeps the local write queued, so keep the emergency flow moving.
      return document.id;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const SosServiceException(
          'Firebase rules blocked this SOS alert. Check Firestore rules and login status.',
        );
      }
      throw SosServiceException(
        error.message ?? 'Could not create SOS alert. Please try again.',
      );
    }

    return document.id;
  }

  User _currentUserOrThrow() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SosServiceException(
        'Please log in before sending an SOS alert.',
      );
    }
    return user;
  }
}
