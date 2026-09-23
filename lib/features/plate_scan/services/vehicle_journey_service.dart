import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/emergency_action_service.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';

class VehicleJourneyService {
  const VehicleJourneyService();

  Future<String> notifyBoarding(String plate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please log in first.');
    final contacts = await const EmergencyContactService()
        .watchEmergencyContacts()
        .first
        .timeout(const Duration(seconds: 12));
    final phones = contacts
        .where((c) => c.isActive)
        .map((c) => c.phone.replaceAll(RegExp(r'\s+'), ''))
        .where((phone) => phone.isNotEmpty)
        .toSet();
    if (phones.isEmpty) {
      return 'No active emergency contacts. Boarding SMS was not sent.';
    }

    var submitted = 0;
    for (final phone in phones) {
      try {
        await const EmergencyActionService().sendEmergencySms(
          phone: phone,
          message:
              'Amica: ${user.displayName ?? "Your contact"} has boarded vehicle $plate. '
              'Destination and journey timer will be selected next.',
        );
        submitted++;
      } catch (_) {
        // Continue to other contacts when one recipient cannot be submitted.
      }
    }
    return 'Boarding SMS submitted for $submitted of ${phones.length} contacts. '
        'Delivery depends on your SIM and network.';
  }

  /// Hard cap on a stored comment, in UTF-16 code units, matching the
  /// Firestore rule. The rating screen already limits typing to 500
  /// characters; Sinhala and Tamil letters can take several code units each,
  /// hence the headroom.
  static const int maxStoredCommentLength = 1000;

  /// Saves her star rating for a finished ride, with an optional [comment].
  /// A blank comment is simply left out.
  Future<void> submitRating(
    String journeyId,
    String plate,
    int stars, {
    String? comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please log in first.');
    if (stars < 1 || stars > 5) throw ArgumentError('Choose 1 to 5 stars.');
    var note = comment?.trim() ?? '';
    if (note.length > maxStoredCommentLength) {
      var cut = maxStoredCommentLength;
      // Never split a surrogate pair (emoji) in half.
      final last = note.codeUnitAt(cut - 1);
      if (last >= 0xD800 && last <= 0xDBFF) cut--;
      note = note.substring(0, cut).trimRight();
    }
    final ref =
        FirebaseFirestore.instance.collection('vehicle_reviews').doc(journeyId);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        if ((await tx.get(ref)).exists) return;
        final journey = (await tx.get(FirebaseFirestore.instance
                .collection('journeys')
                .doc(journeyId)))
            .data();
        if (journey == null ||
            journey['userId'] != user.uid ||
            journey['status'] != 'safe') {
          throw const VehicleRatingException(
              'Mark this journey safe before submitting a rating.');
        }
        if (journey['metadata'] is! Map ||
            journey['metadata']['vehiclePlate'] != plate) {
          throw const VehicleRatingException(
              'This journey has no matching vehicle. Open its original vehicle journey.');
        }
        tx.set(ref, {
          'userId': user.uid,
          'vehiclePlate': plate,
          'stars': stars,
          if (note.isNotEmpty) 'comment': note,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }).timeout(const Duration(seconds: 20));
    } on FirebaseException catch (error) {
      throw VehicleRatingException(ratingErrorMessage(error.code));
    } on TimeoutException {
      throw const VehicleRatingException(
          'Rating confirmation timed out. Reconnect and retry; this journey will not be counted twice.');
    }
  }

  static String ratingErrorMessage(String code) => switch (code) {
        'permission-denied' =>
          'Rating access was denied. The development backend must include the vehicle review rules. Ask the project maintainer to deploy them.',
        'unavailable' =>
          'Rating could not reach the database. Check your connection and retry.',
        'unauthenticated' =>
          'Your session has expired. Log in again to submit your rating.',
        _ => 'Could not submit the rating. Please retry.',
      };

  Future<void> recordMissedCheck(String journeyId, String plate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('vehicle_safety_events')
        .doc(journeyId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, {
        'userId': user.uid,
        'vehiclePlate': plate,
        'type': 'unanswered_safety_check',
        'createdAt': FieldValue.serverTimestamp()
      });
    });
  }
}

class VehicleRatingException implements Exception {
  const VehicleRatingException(this.message);
  final String message;
  @override
  String toString() => message;
}
