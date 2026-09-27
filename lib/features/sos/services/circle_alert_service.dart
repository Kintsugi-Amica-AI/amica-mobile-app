import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/emergency_action_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';

/// Where one guardian's SOS text got to.
enum CircleDelivery {
  /// Still going out.
  sending,

  /// The phone's radio confirmed the SMS left the phone.
  sent,

  /// Handed to the SIM but no confirmation came back in time. It may well
  /// have arrived — the screen says "not confirmed", never "sent".
  unconfirmed,

  /// Definitely not sent (no service, no SMS balance, permission refused…).
  failed,
}

class CircleDeliveryResult {
  const CircleDeliveryResult({
    required this.contact,
    required this.delivery,
    this.error,
  });

  final EmergencyContact contact;
  final CircleDelivery delivery;
  final String? error;

  bool get reached =>
      delivery == CircleDelivery.sent ||
      delivery == CircleDelivery.unconfirmed;
}

/// Texts the whole circle when an SOS goes out.
///
/// Until now a manual SOS (the hold button on Home, "Send SOS" on a
/// journey) only wrote an `sos_alerts` record — the backend notifier is
/// still a placeholder — so nobody was told, while the screen said
/// "Notified". This sends an SMS with her live location to every active
/// guardian from her own SIM, and reports honestly per person.
class CircleAlertService {
  const CircleAlertService({
    this.contactService = const EmergencyContactService(),
    this.actionService = const EmergencyActionService(),
  });

  final EmergencyContactService contactService;
  final EmergencyActionService actionService;

  static String mapsLink(double latitude, double longitude) =>
      'https://maps.google.com/?q=${latitude.toStringAsFixed(6)},'
      '${longitude.toStringAsFixed(6)}';

  static String _normalizedPhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Active guardians with a phone number, one per number.
  Future<List<EmergencyContact>> activeGuardians() async {
    final contacts = await contactService
        .watchEmergencyContacts()
        .first
        .timeout(const Duration(seconds: 10));
    final seen = <String>{};
    return [
      for (final c in contacts)
        if (c.isActive &&
            c.phone.trim().isNotEmpty &&
            seen.add(_normalizedPhone(c.phone)))
          c,
    ];
  }

  /// Sends [message] to [guardians], reporting each result through
  /// [onUpdate] as it happens, and returns the final results.
  ///
  /// The first text goes alone so Android can ask for SMS permission once;
  /// the rest go out together so a slow confirmation for one person never
  /// holds up the others.
  Future<List<CircleDeliveryResult>> sendToCircle({
    required List<EmergencyContact> guardians,
    required String message,
    void Function(CircleDeliveryResult result)? onUpdate,
    String? alertId,
  }) async {
    Future<CircleDeliveryResult> sendOne(EmergencyContact contact) async {
      CircleDeliveryResult result;
      try {
        final status = await actionService.sendEmergencySms(
          phone: _normalizedPhone(contact.phone),
          message: message,
        );
        result = CircleDeliveryResult(
          contact: contact,
          delivery: status == SmsSendStatus.sent
              ? CircleDelivery.sent
              : CircleDelivery.unconfirmed,
        );
      } on EmergencyActionException catch (error) {
        result = CircleDeliveryResult(
          contact: contact,
          delivery: CircleDelivery.failed,
          error: error.message,
        );
      } catch (error) {
        result = CircleDeliveryResult(
          contact: contact,
          delivery: CircleDelivery.failed,
          error: '$error',
        );
      }
      onUpdate?.call(result);
      return result;
    }

    if (guardians.isEmpty) return const [];
    final first = await sendOne(guardians.first);
    final rest = await Future.wait(guardians.skip(1).map(sendOne));
    final results = [first, ...rest];

    if (alertId != null) {
      unawaited(_record(alertId, results));
    }
    return results;
  }

  /// Best effort: note on the SOS record who was reached.
  Future<void> _record(String alertId, List<CircleDeliveryResult> results) {
    return FirebaseFirestore.instance
        .collection('sos_alerts')
        .doc(alertId)
        .update({
          'notifiedContacts': [
            for (final r in results)
              if (r.reached) r.contact.id,
          ],
          'deliveryReport': {
            for (final r in results)
              r.contact.id: {
                'status': r.delivery.name,
                if (r.error != null) 'error': r.error,
              },
          },
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 12))
        .catchError((_) {});
  }
}
