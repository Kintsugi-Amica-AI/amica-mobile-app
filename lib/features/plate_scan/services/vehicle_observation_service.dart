import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/vehicle_match.dart';
import 'vehicle_inspector.dart';

/// Shares what the camera saw (type and colour words only, never the
/// photo) so the community can learn each plate's usual vehicle.
///
/// Each user counts once per plate: the document id is
/// `{plate}_{uid}` and Firestore rules refuse updates, so re-scanning
/// the same car cannot tip its profile. The `onVehicleObservationCreated`
/// Cloud Function folds new observations into `vehicles/{plate}`.
class VehicleObservationService {
  const VehicleObservationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  static final RegExp _letterSeriesPlate = RegExp(r'^[A-Z]{2,3}[0-9]{4}$');

  /// The fields worth sharing, or null when nothing was read confidently.
  /// Pure, so it is unit tested without Firebase.
  static Map<String, String>? observationFields(VehicleInspection inspection) {
    final fields = <String, String>{};
    final type = inspection.type;
    final kind = type?.bestKind;
    if (type != null &&
        kind != null &&
        type.confidence >= VehicleMatcher.minTypeConfidence) {
      fields['vehicleType'] = kind.id;
    }
    final colour = inspection.colour;
    if (colour != null && colour.isReliable) {
      fields['colour'] = colour.colour!.id;
    }
    return fields.isEmpty ? null : fields;
  }

  /// Best effort: never throws, never delays the result screen.
  Future<void> record(String plate, VehicleInspection inspection) async {
    try {
      final fields = observationFields(inspection);
      if (fields == null || !_letterSeriesPlate.hasMatch(plate)) return;
      final user = (_auth ?? FirebaseAuth.instance).currentUser;
      if (user == null) return;
      final db = _firestore ?? FirebaseFirestore.instance;
      final ref =
          db.collection('vehicle_observations').doc('${plate}_${user.uid}');
      // A second scan of the same plate is an update, which the rules
      // refuse; that is expected and ignored.
      await ref.set({
        'userId': user.uid,
        'vehiclePlate': plate,
        ...fields,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('VehicleObservationService: not recorded ($error)');
    }
  }
}
