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
  static const String _defaultMessage = 'I need help. This is my live location.';

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

  Future<String> _createSosAlert({
    required String triggerType,
    required LocationDataModel location,
    String? journeyId,
  }) async {
    final user = _currentUserOrThrow();
    final document = _firestore.collection(_collectionName).doc();

    await document.set({
      'id': document.id,
      'userId': user.uid,
      if (journeyId != null) 'journeyId': journeyId,
      'triggerType': triggerType,
      'status': 'active',
      'location': location.toMap(),
      'message': _defaultMessage,
      'notifiedContacts': const <String>[],
      'evidence': const <String, dynamic>{},
      'metadata': const <String, dynamic>{},
      'schemaVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

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
