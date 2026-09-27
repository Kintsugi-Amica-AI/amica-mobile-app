import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/live_location_tracker.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../sos/services/circle_alert_service.dart';

class JourneyShareException implements Exception {
  const JourneyShareException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What happened the last time the live link went out to her circle.
class JourneyShareOutcome {
  const JourneyShareOutcome({
    required this.journeyId,
    required this.url,
    this.pushed = 0,
    this.texted = 0,
    this.failed = 0,
    this.sending = false,
    this.error,
  });

  final String journeyId;
  final String? url;

  /// Contacts reached by an Amica notification (no SMS needed).
  final int pushed;

  /// Contacts the phone confirmed (or handed to the SIM) an SMS for.
  final int texted;

  /// Contacts nothing could be sent to.
  final int failed;
  final bool sending;
  final String? error;

  JourneyShareOutcome copyWith({
    String? url,
    int? pushed,
    int? texted,
    int? failed,
    bool? sending,
    String? error,
  }) {
    return JourneyShareOutcome(
      journeyId: journeyId,
      url: url ?? this.url,
      pushed: pushed ?? this.pushed,
      texted: texted ?? this.texted,
      failed: failed ?? this.failed,
      sending: sending ?? this.sending,
      error: error,
    );
  }
}

/// "Watch my journey live": creates the link, keeps her position flowing to
/// it, and sends it to her circle — a free push to contacts who have Amica,
/// an SMS from her own SIM to everyone else.
class JourneyShareService {
  JourneyShareService._();

  static final JourneyShareService instance = JourneyShareService._();

  static const String _prefsKey = 'amica_share_live_default';

  /// The latest outcome, for the journey screen's share card.
  final ValueNotifier<JourneyShareOutcome?> outcome =
      ValueNotifier<JourneyShareOutcome?>(null);

  final CircleAlertService _circle = const CircleAlertService();

  /// Whether "Share live with my circle" starts switched on. Defaults to on.
  Future<bool> loadShareByDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> saveShareByDefault(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {/* Only a remembered default. */}
  }

  /// Makes sure the link exists and her location is being sent, without
  /// telling anyone. Used when the journey screen reopens.
  Future<void> resumeTracking(String journeyId, AppLocalizations loc) async {
    _localiseTracker(loc);
    await LiveLocationTracker.instance.start(journeyId);
  }

  /// Creates the live link (or reuses it), starts sending her location and,
  /// with [notifyCircle], sends the link to every active contact.
  Future<JourneyShareOutcome> shareWithCircle({
    required String journeyId,
    required String destinationName,
    required AppLocalizations loc,
    bool notifyCircle = true,
  }) async {
    outcome.value = JourneyShareOutcome(
      journeyId: journeyId,
      url: outcome.value?.journeyId == journeyId ? outcome.value?.url : null,
      sending: true,
    );

    _localiseTracker(loc);
    unawaited(LiveLocationTracker.instance.start(journeyId));

    final String url;
    final Set<String> pushedContactIds;
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('startJourneyShare')
          .call<dynamic>({
        'journeyId': journeyId,
        'notifyCircle': notifyCircle,
      }).timeout(const Duration(seconds: 25));
      final data = result.data is Map
          ? Map<String, dynamic>.from(result.data as Map)
          : const <String, dynamic>{};
      url = data['url'] as String? ?? '';
      pushedContactIds = {
        for (final id in (data['pushedContactIds'] as List? ?? const []))
          if (id is String) id,
      };
      if (url.isEmpty) {
        throw const JourneyShareException('No link came back.');
      }
    } catch (error) {
      final failed = JourneyShareOutcome(
        journeyId: journeyId,
        url: null,
        error: error is FirebaseFunctionsException
            ? (error.message ?? loc.liveShareCreateFailed)
            : loc.liveShareCreateFailed,
      );
      outcome.value = failed;
      return failed;
    }

    var current = JourneyShareOutcome(
      journeyId: journeyId,
      url: url,
      pushed: pushedContactIds.length,
      sending: notifyCircle,
    );
    outcome.value = current;
    if (!notifyCircle) {
      return current;
    }

    List<EmergencyContact> guardians;
    try {
      guardians = await _circle.activeGuardians();
    } catch (_) {
      current = current.copyWith(sending: false, error: loc.liveShareContactsFailed);
      outcome.value = current;
      return current;
    }

    // Contacts who just got a push don't need to pay for an SMS as well.
    final smsTargets = [
      for (final g in guardians)
        if (!pushedContactIds.contains(g.id)) g,
    ];
    if (smsTargets.isNotEmpty) {
      final results = await _circle.sendToCircle(
        guardians: smsTargets,
        message: _smsText(loc, destinationName, url),
      );
      current = current.copyWith(
        texted: results.where((r) => r.reached).length,
        failed: results.where((r) => !r.reached).length,
      );
    }
    current = current.copyWith(sending: false);
    outcome.value = current;
    return current;
  }

  String _smsText(AppLocalizations loc, String destinationName, String url) {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final first = name.split(RegExp(r'\s+')).first;
    return first.isEmpty
        ? loc.liveShareSmsNoName(destinationName, url)
        : loc.liveShareSmsWithName(first, destinationName, url);
  }

  void _localiseTracker(AppLocalizations loc) {
    LiveLocationTracker.instance
      ..notificationTitle = loc.liveShareTrackingTitle
      ..notificationText = loc.liveShareTrackingText;
  }
}
