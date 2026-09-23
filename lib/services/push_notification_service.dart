import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_routes.dart';
import '../features/circle/models/guardian_alert.dart';
import '../features/circle/services/guardian_link_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Runs in its own isolate when a push arrives with Amica closed or in the
/// background. Draws the notification (with the reply buttons).
@pragma('vm:entry-point')
Future<void> amicaFirebaseBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await PushNotificationService.instance.showFromData(message.data);
}

/// Runs when a reply button that does not open Amica ("I've alerted
/// others") is tapped while Amica is not running.
@pragma('vm:entry-point')
void amicaNotificationBackgroundResponse(NotificationResponse response) {
  DartPluginRegistrant.ensureInitialized();
  unawaited(PushNotificationService.instance.handleBackgroundAction(response));
}

/// Push notifications for Amica users who are in someone's circle, and for
/// her own phone when a guardian replies.
///
/// All pushes are data-only (see the backend's pushService), so this class
/// always draws the notification: in her language, with one-tap replies.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String sosChannelId = 'amica_sos_alerts';
  static const String updatesChannelId = 'amica_circle_updates';
  static const String actionCallingNow = 'calling_now';
  static const String actionAlertedOthers = 'alerted_others';
  static const String actionWatchLive = 'watch_live';
  static const String _localeKey = 'amica_locale_code';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final GuardianLinkService _guardianService = const GuardianLinkService();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _pluginReady = false;
  bool _started = false;
  String? _registeredToken;
  String? _registeredUid;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  /// Call once from the app, after Firebase is initialised.
  Future<void> start({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;
    if (_started) return;

    try {
      if (Firebase.apps.isEmpty) return;
      _started = true;
      await _ensurePlugin();
      _messageSubscription = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) unawaited(_register(user));
      });

      // Opened by tapping a notification while Amica was closed.
      final launch = await _notifications.getNotificationAppLaunchDetails();
      final response = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && response != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => unawaited(_handleResponse(response)),
        );
      }
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  /// Removes this device's token before signing out, so her alerts stop
  /// arriving on a phone someone else now uses.
  Future<void> unregister() async {
    final token = _registeredToken;
    _registeredToken = null;
    _registeredUid = null;
    if (token == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(token)
          .delete()
          .timeout(const Duration(seconds: 8));
    } catch (_) {/* The backend also prunes dead tokens. */}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    _started = false;
  }

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  Future<void> _register(User user) async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(user.uid, token);
      await _tokenSubscription?.cancel();
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (fresh) {
          final current = FirebaseAuth.instance.currentUser;
          if (current != null) unawaited(_saveToken(current.uid, fresh));
        },
      );
    } catch (error) {
      debugPrint('Could not register for push: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    if (_registeredToken == token && _registeredUid == uid) return;
    await FirebaseFirestore.instance.collection('fcm_tokens').doc(token).set({
      'userId': uid,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _registeredToken = token;
    _registeredUid = uid;
  }

  // ---------------------------------------------------------------------------
  // Showing notifications
  // ---------------------------------------------------------------------------

  Future<void> _ensurePlugin() async {
    if (_pluginReady) return;
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_amica'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          unawaited(_handleResponse(response)),
      onDidReceiveBackgroundNotificationResponse:
          amicaNotificationBackgroundResponse,
    );

    final loc = await _localizations();
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(AndroidNotificationChannel(
      sosChannelId,
      loc.pushChannelSosName,
      description: loc.pushChannelSosDescription,
      importance: Importance.max,
    ));
    await android?.createNotificationChannel(AndroidNotificationChannel(
      updatesChannelId,
      loc.pushChannelUpdatesName,
      description: loc.pushChannelUpdatesDescription,
      importance: Importance.high,
    ));
    _pluginReady = true;
  }

  Future<AppLocalizations> _localizations() async {
    var code = PlatformDispatcher.instance.locale.languageCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      code = prefs.getString(_localeKey) ?? code;
    } catch (_) {}
    const supported = {'en', 'si', 'ta'};
    return lookupAppLocalizations(Locale(supported.contains(code) ? code : 'en'));
  }

  static int _notificationId(GuardianAlert alert) {
    final key = alert.alertId ?? alert.journeyId ?? alert.type;
    return '${alert.type}:$key'.hashCode & 0x7fffffff;
  }

  /// Draws the notification for a push's data payload.
  Future<void> showFromData(Map<String, dynamic> data) async {
    final alert = GuardianAlert.fromData({
      ...data,
      'receivedAt': DateTime.now().toIso8601String(),
    });
    if (alert.type.isEmpty) return;
    await _ensurePlugin();
    final loc = await _localizations();

    final owner = alert.ownerName.isEmpty ? loc.pushSomeone : alert.ownerName;
    final guardian =
        alert.guardianName.isEmpty ? loc.pushYourContact : alert.guardianName;
    final dest = alert.destinationName;

    late final String title;
    late final String body;
    var actions = <AndroidNotificationAction>[];
    var channel = updatesChannelId;

    switch (alert.type) {
      case 'sos':
        channel = sosChannelId;
        title = loc.pushSosTitle(owner);
        body = alert.latitude != null ? loc.pushSosBody : loc.pushSosBodyNoLocation;
        actions = [
          AndroidNotificationAction(
            actionCallingNow,
            loc.pushActionCallingNow,
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            actionAlertedOthers,
            loc.pushActionAlertedOthers,
          ),
        ];
      case 'journey_started':
        title = loc.pushJourneyStartedTitle(owner);
        body = dest.isEmpty
            ? loc.pushJourneyStartedBodyNoDest
            : loc.pushJourneyStartedBody(dest);
        if (alert.liveUrl != null) {
          actions = [
            AndroidNotificationAction(
              actionWatchLive,
              loc.pushActionWatchLive,
              showsUserInterface: true,
            ),
          ];
        }
      case 'journey_arrived':
        title = loc.pushArrivedTitle(owner);
        body = dest.isEmpty ? loc.pushArrivedBodyNoDest : loc.pushArrivedBody(dest);
      case 'guardian_response':
        final calling = alert.response == GuardianResponse.calling.wireName;
        title = calling
            ? loc.pushResponseCallingTitle(guardian)
            : loc.pushResponseAlertedTitle(guardian);
        body = calling ? loc.pushResponseCallingBody : loc.pushResponseAlertedBody;
      case 'guardian_linked':
        title = loc.pushLinkedTitle(guardian);
        body = loc.pushLinkedBody;
      default:
        final fallbackTitle = data['title'];
        if (fallbackTitle is! String || fallbackTitle.isEmpty) return;
        title = fallbackTitle;
        body = data['body'] is String ? data['body'] as String : '';
    }

    final isSos = channel == sosChannelId;
    await _notifications.show(
      _notificationId(alert),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          isSos ? loc.pushChannelSosName : loc.pushChannelUpdatesName,
          channelDescription: isSos
              ? loc.pushChannelSosDescription
              : loc.pushChannelUpdatesDescription,
          importance: isSos ? Importance.max : Importance.high,
          priority: isSos ? Priority.max : Priority.high,
          category: isSos
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.message,
          color: const Color(0xFFD93360),
          visibility: NotificationVisibility.public,
          vibrationPattern: isSos
              ? Int64List.fromList([0, 600, 250, 600, 250, 600])
              : null,
          styleInformation: BigTextStyleInformation(body),
          actions: actions,
          ongoing: false,
          autoCancel: true,
        ),
      ),
      payload: jsonEncode(alert.toData()),
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await showFromData(message.data);
    // With Amica open, an SOS goes straight to the full screen as well.
    if (message.data['type'] == 'sos') {
      final alert = GuardianAlert.fromData({
        ...message.data,
        'receivedAt': DateTime.now().toIso8601String(),
      });
      _navigatorKey?.currentState?.pushNamed(
        AppRoutes.guardianAlert,
        arguments: alert,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Taps and reply buttons
  // ---------------------------------------------------------------------------

  GuardianAlert? _alertFrom(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map
          ? GuardianAlert.fromData(Map<String, dynamic>.from(decoded))
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final alert = _alertFrom(response);
    if (alert == null) return;
    final navigator = _navigatorKey?.currentState;

    switch (response.actionId) {
      case actionCallingNow:
        await callingNow(alert);
        navigator?.pushNamed(AppRoutes.guardianAlert, arguments: alert);
        return;
      case actionAlertedOthers:
        await _respond(alert, GuardianResponse.alertedOthers);
        return;
      case actionWatchLive:
        await _openLink(alert.liveUrl);
        return;
    }

    // Plain tap on the notification.
    switch (alert.type) {
      case 'sos':
        navigator?.pushNamed(AppRoutes.guardianAlert, arguments: alert);
      case 'journey_started':
        if (alert.liveUrl != null) {
          await _openLink(alert.liveUrl);
        } else {
          navigator?.pushNamed(AppRoutes.guardianAlert, arguments: alert);
        }
      case 'guardian_linked':
        navigator?.pushNamed(AppRoutes.emergencyContacts);
      default:
        break;
    }
  }

  /// "Calling now": tells her, then opens the dialler with her number.
  Future<void> callingNow(GuardianAlert alert) async {
    unawaited(_respond(alert, GuardianResponse.calling));
    if (alert.ownerPhone.isNotEmpty) {
      try {
        await launchUrl(Uri(scheme: 'tel', path: alert.ownerPhone));
      } catch (_) {}
    }
  }

  /// Sends a one-tap reply. Returns false if it could not be delivered.
  Future<bool> respond(GuardianAlert alert, GuardianResponse response) =>
      _respond(alert, response);

  Future<bool> _respond(GuardianAlert alert, GuardianResponse response) async {
    final alertId = alert.alertId;
    if (alertId == null) return false;
    try {
      await _guardianService.respond(alertId, response);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// A reply button tapped with Amica not running: sign-in is restored from
  /// disk, the reply is sent, and a short notification confirms it.
  Future<void> handleBackgroundAction(NotificationResponse response) async {
    if (response.actionId != actionAlertedOthers) return;
    final alert = _alertFrom(response);
    if (alert == null) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      return;
    }
    final sent = await _respond(alert, GuardianResponse.alertedOthers);
    await _ensurePlugin();
    final loc = await _localizations();
    await _notifications.show(
      _notificationId(alert),
      sent ? loc.pushResponseSentTitle : loc.pushResponseFailedTitle,
      sent
          ? loc.pushResponseSentAlertedBody(
              alert.ownerName.isEmpty ? loc.pushSomeone : alert.ownerName)
          : loc.pushResponseFailedBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          updatesChannelId,
          loc.pushChannelUpdatesName,
          channelDescription: loc.pushChannelUpdatesDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(alert.toData()),
    );
  }

  Future<void> _openLink(String? url) async {
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
