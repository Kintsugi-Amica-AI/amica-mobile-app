import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

class GuardianLinkException implements Exception {
  const GuardianLinkException(this.message, {this.reason});

  final String message;

  /// `not_found`, `expired`, `used` or `own_invite` when the backend said so.
  final String? reason;

  @override
  String toString() => message;
}

class GuardianInvite {
  const GuardianInvite({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

class GuardedPerson {
  const GuardedPerson({required this.contactId, required this.ownerName});

  final String contactId;
  final String ownerName;
}

/// One-tap replies a guardian can send back to an SOS.
enum GuardianResponse {
  calling('calling'),
  alertedOthers('alerted_others');

  const GuardianResponse(this.wireName);

  final String wireName;

  static GuardianResponse? fromWire(Object? value) {
    for (final response in values) {
      if (response.wireName == value) return response;
    }
    return null;
  }
}

/// Linking emergency contacts to their own Amica accounts, and a guardian's
/// replies to an alert. All of it runs through Cloud Functions: clients
/// cannot set `guardianUid` themselves (see firestore.rules).
class GuardianLinkService {
  const GuardianLinkService();

  static const Duration _timeout = Duration(seconds: 20);

  HttpsCallable _callable(String name) =>
      FirebaseFunctions.instance.httpsCallable(name);

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _callable(name).call<dynamic>(data).timeout(_timeout);
      final value = result.data;
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    } on FirebaseFunctionsException catch (error) {
      final details = error.details;
      throw GuardianLinkException(
        error.message ?? 'Something went wrong. Please try again.',
        reason: details is Map ? details['reason'] as String? : null,
      );
    } on TimeoutException {
      throw const GuardianLinkException(
        'No connection. Check your internet and try again.',
        reason: 'timeout',
      );
    }
  }

  /// A code for [contactId] to enter in their Amica app.
  Future<GuardianInvite> createInvite(String contactId) async {
    final data = await _call('createGuardianInvite', {'contactId': contactId});
    return GuardianInvite(
      code: data['code'] as String? ?? '',
      expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Links this account to whoever sent [code]. Returns their first name.
  Future<String> acceptInvite(String code) async {
    final data = await _call('acceptGuardianInvite', {'code': code});
    return data['ownerName'] as String? ?? '';
  }

  Future<List<GuardedPerson>> listGuarding() async {
    final data = await _call('listGuarding', const {});
    final list = data['guarding'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          GuardedPerson(
            contactId: item['contactId'] as String? ?? '',
            ownerName: item['ownerName'] as String? ?? '',
          ),
    ];
  }

  Future<void> unlink(String contactId) async {
    await _call('unlinkGuardian', {'contactId': contactId});
  }

  Future<void> respond(String alertId, GuardianResponse response) async {
    await _call('respondToAlert', {
      'alertId': alertId,
      'response': response.wireName,
    });
  }
}
