import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/emergency_action_service.dart';
import '../../../services/journey_route_service.dart';
import '../../../services/location_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../models/journey.dart';
import '../models/location_data_model.dart';
import '../services/journey_service.dart';
import '../widgets/journey_visuals.dart';
import 'safety_check_screen.dart';
import '../../plate_scan/screens/vehicle_rating_screen.dart';
import '../../plate_scan/services/vehicle_journey_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class JourneyTimerScreen extends StatefulWidget {
  const JourneyTimerScreen({
    super.key,
    this.journeyId,
    this.isTab = false,
    this.journeyService = const JourneyService(),
    this.locationService = const LocationService(),
    this.sosService = const SosService(),
    this.emergencyContactService = const EmergencyContactService(),
    this.emergencyActionService = const EmergencyActionService(),
    this.routeService = const JourneyRouteService(),
  });

  final String? journeyId;

  /// True when shown as the Journeys tab rather than pushed as a route.
  final bool isTab;
  final JourneyService journeyService;
  final LocationService locationService;
  final SosService sosService;
  final EmergencyContactService emergencyContactService;
  final EmergencyActionService emergencyActionService;
  final JourneyRouteService routeService;

  @override
  State<JourneyTimerScreen> createState() => _JourneyTimerScreenState();
}

class _JourneyTimerScreenState extends State<JourneyTimerScreen>
    with WidgetsBindingObserver {
  /// How long after the safety check the primary emergency contact is
  /// messaged, and then called, if the user still has not answered.
  ///
  /// These mirror `SMS_DELAY_MILLIS` and `CALL_DELAY_MILLIS` in the native
  /// `EmergencySafetyMonitorService`, so the countdown shown on the safety
  /// check screen matches what actually happens on either path.
  static const Duration _messageEscalationDelay = Duration(minutes: 1);
  static const Duration _callEscalationDelay = Duration(minutes: 3);

  final ValueNotifier<Duration> _remainingNotifier =
      ValueNotifier<Duration>(Duration.zero);

  /// Time left in the current pause, or null while the timer is running.
  final ValueNotifier<Duration?> _pauseLeftNotifier =
      ValueNotifier<Duration?>(null);

  StreamSubscription<Journey?>? _journeySubscription;
  Timer? _countdownTimer;
  Timer? _safetyMessageTimer;
  Timer? _safetyCallTimer;
  Journey? _journey;
  Journey? _safetyCheckJourney;
  Object? _journeyError;
  DateTime? _safetyCheckShownAt;
  bool _isLoadingJourney = true;
  bool _isSaving = false;
  bool _safetyDialogShown = false;
  bool _nativeSafetyMonitorStarted = false;
  bool _nativeSafetyMonitorStarting = false;
  bool _messageEscalationHandled = false;
  bool _callEscalationHandled = false;
  String? _nativeSafetyMonitorJourneyId;

  /// The deadline the native monitor was last started with. Pausing and
  /// resuming move the deadline, so the monitor is restarted when it changes.
  DateTime? _nativeSafetyMonitorCheckAt;
  bool _isPausing = false;
  int _journeyListenRetries = 0;
  static const int _maxJourneyListenRetries = 5;
  bool _wasPaused = false;
  JourneyRoute? _fallbackRoute;
  bool _fallbackRouteRequested = false;
  bool _incidentRecorded = false;
  bool _incidentSyncing = false;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToJourney();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingAndSafetyState(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateRemainingAndSafetyState();
      _runMissedSafetyEscalations();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _journeySubscription?.cancel();
    _countdownTimer?.cancel();
    _cancelSafetyEscalations();
    _remainingNotifier.dispose();
    _pauseLeftNotifier.dispose();
    super.dispose();
  }

  void _listenToJourney() {
    _journeySubscription = _journeyStream().listen(
      (journey) {
        if (!mounted) {
          return;
        }
        _journeyListenRetries = 0;
        setState(() {
          _journey = journey;
          _journeyError = null;
          _isLoadingJourney = false;
        });
        unawaited(_startNativeSafetyMonitorIfNeeded(journey));
        _updateRemainingAndSafetyState();
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        // A brand-new journey can be denied for a moment, until the server
        // has the document. Firestore closes the listener on that error, so
        // listen again a few times before showing it.
        if (error is FirebaseException &&
            error.code == 'permission-denied' &&
            _journeyListenRetries < _maxJourneyListenRetries) {
          _journeyListenRetries++;
          _journeySubscription?.cancel();
          Future<void>.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _listenToJourney();
            }
          });
          return;
        }
        setState(() {
          _journeyError = error;
          _isLoadingJourney = false;
        });
      },
    );
  }

  Stream<Journey?> _journeyStream() {
    final journeyId = widget.journeyId;
    if (journeyId == null || journeyId.isEmpty) {
      return widget.journeyService.watchActiveJourney();
    }
    return widget.journeyService.watchJourney(journeyId);
  }

  Duration _remaining(Journey journey) {
    if (journey.isPausedAt(DateTime.now())) {
      return journey.pausedRemaining;
    }
    final remaining = journey.estimatedEndTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _updateRemainingAndSafetyState() {
    final journey = _journey;
    if (journey != null &&
        journey.metadata['vehiclePlate'] is String &&
        DateTime.now()
            .isAfter(journey.estimatedEndTime.add(_callEscalationDelay))) {
      unawaited(_syncMissedCheck(journey));
    }
    if (journey == null || !journey.isActive) {
      return;
    }

    final now = DateTime.now();
    final isPaused = journey.isPausedAt(now);
    final resumeAt = journey.pauseResumeAt;
    _pauseLeftNotifier.value =
        isPaused && resumeAt != null ? resumeAt.difference(now) : null;
    if (isPaused != _wasPaused) {
      // A pause just started or ran out on its own: swap Pause/Resume.
      _wasPaused = isPaused;
      if (mounted) {
        setState(() {});
      }
    }

    final remaining = _remaining(journey);
    if (_remainingNotifier.value != remaining) {
      _remainingNotifier.value = remaining;
    }

    if (remaining == Duration.zero) {
      _maybeShowSafetyDialog(journey);
    }
  }

  Future<void> _syncMissedCheck(Journey journey) async {
    if (_incidentRecorded || _incidentSyncing) return;
    _incidentSyncing = true;
    try {
      if (_callEscalationHandled ||
          await widget.emergencyActionService
              .hasJourneyCallEscalated(journey.id)) {
        await const VehicleJourneyService().recordMissedCheck(
            journey.id, journey.metadata['vehiclePlate'] as String);
        _incidentRecorded = true;
      }
    } catch (_) {
      // Retry on a later tick/resume if offline. The record uses the journey ID.
    } finally {
      _incidentSyncing = false;
    }
  }

  Future<LocationDataModel> _currentOrFallbackLocation(Journey journey) async {
    try {
      final location = await widget.locationService.getCurrentLocationData();
      await widget.journeyService.updateCurrentLocation(journey.id, location);
      return location;
    } catch (_) {
      final fallback = journey.currentLocation ?? journey.startLocation;
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }

  LocationDataModel? _cachedJourneyLocation(Journey journey) {
    return journey.currentLocation ?? journey.startLocation;
  }

  Future<LocationDataModel> _sosLocation(Journey journey) async {
    final cachedLocation = _cachedJourneyLocation(journey);
    if (cachedLocation != null) {
      unawaited(
        widget.locationService
            .getCurrentLocationData()
            .then(
              (location) => widget.journeyService
                  .updateCurrentLocation(journey.id, location),
            )
            .catchError((_) {}),
      );
      return cachedLocation;
    }

    return _currentOrFallbackLocation(journey);
  }

  Future<void> _markSafe(Journey journey) async {
    _cancelSafetyEscalations();
    setState(() => _isSaving = true);
    try {
      await _stopNativeSafetyMonitor();
      await widget.journeyService.markJourneySafe(journey.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.journeyTimerMarkedSafe)),
      );
      final plate = journey.metadata['vehiclePlate'];
      if (plate is String && plate.isNotEmpty) {
        await Navigator.push(
            context,
            MaterialPageRoute<void>(
                builder: (_) =>
                    VehicleRatingScreen(journeyId: journey.id, plate: plate)));
        if (!mounted) return;
      }
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loc.journeyTimerMarkSafeFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendSos(Journey journey, {bool timerTriggered = false}) async {
    _cancelSafetyEscalations();
    setState(() => _isSaving = true);
    _showEscalationSnack(_loc.journeyTimerSendingSos);
    try {
      await _stopNativeSafetyMonitor();
      final location = await _sosLocation(journey);
      final alertId = timerTriggered
          ? await widget.sosService.createTimerSosAlert(
              location: location,
              journeyId: journey.id,
            )
          : await widget.sosService.createManualSosAlert(
              location: location,
              journeyId: journey.id,
            );
      unawaited(
        widget.journeyService.markJourneySos(journey.id).catchError((_) {}),
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sosActive,
        arguments: SosActiveArguments(
          alertId: alertId,
          triggerType: timerTriggered ? 'timer' : 'manual',
          location: location,
        ),
      );
    } on SosServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } on LocationServiceException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loc.journeyTimerSosCreateFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _maybeShowSafetyDialog(Journey journey) {
    if (_safetyDialogShown) {
      return;
    }

    _safetyDialogShown = true;
    _safetyCheckJourney = journey;
    _safetyCheckShownAt = DateTime.now();

    if (!_nativeSafetyMonitorStarted) {
      _scheduleSafetyEscalations(journey);
      unawaited(_vibrateTwiceForSafetyCheck());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_openSafetyCheck(journey));
    });
  }

  /// Opens the full-screen safety check and applies the user's answer.
  ///
  /// The screen itself only reports a decision; this screen keeps ownership of
  /// the journey document, the native safety monitor, and the escalation
  /// timers, which all keep running underneath while the check is on top.
  Future<void> _openSafetyCheck(Journey journey) async {
    final result = await Navigator.pushNamed<Object?>(
      context,
      AppRoutes.safetyCheck,
      arguments: SafetyCheckArguments(
        destinationName: journey.destinationName,
        journeyId: journey.id,
        escalationAt: journey.estimatedEndTime.add(_messageEscalationDelay),
      ),
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case SafetyCheckResult.safe:
        await _markSafe(journey);
      case SafetyCheckResult.sos:
        await _sendSos(journey, timerTriggered: true);
      default:
        // The check is not dismissible, so this only happens if the route was
        // torn down (for example the app was killed). Leave the escalation
        // timers and the native monitor running.
        break;
    }
  }

  Future<void> _vibrateTwiceForSafetyCheck() async {
    try {
      await widget.emergencyActionService.vibrateTwice();
    } catch (_) {
      // Vibration support varies by emulator/device, so keep the safety flow moving.
    }
  }

  Future<void> _startNativeSafetyMonitorIfNeeded(Journey? journey) async {
    // An SOS status must not cancel the pending three-minute call.
    if (journey?.status == 'sos') return;
    if (journey == null || !journey.isActive) {
      await _stopNativeSafetyMonitor();
      return;
    }

    if (_nativeSafetyMonitorStarting ||
        (_nativeSafetyMonitorJourneyId == journey.id &&
            _nativeSafetyMonitorCheckAt == journey.estimatedEndTime)) {
      return;
    }

    _nativeSafetyMonitorStarting = true;
    try {
      await widget.emergencyActionService.prepareEmergencyPermissions();

      final contacts = await widget.emergencyContactService
          .watchEmergencyContacts()
          .first
          .timeout(const Duration(seconds: 12));
      final activeContacts = contacts
          .where((c) => c.isActive && c.phone.trim().isNotEmpty)
          .toList();
      final contact = activeContacts.isEmpty ? null : activeContacts.first;
      final location = journey.currentLocation ?? journey.startLocation;

      await widget.emergencyActionService.startJourneySafetyMonitor(
        journeyId: journey.id,
        destinationName: journey.destinationName,
        safetyCheckAt: journey.estimatedEndTime,
        emergencyPhone: contact == null ? '' : _normalizedPhone(contact.phone),
        emergencyMessage: _buildEmergencyMessage(journey, location),
        emergencyPhones: activeContacts
            .map((c) => _normalizedPhone(c.phone))
            .toSet()
            .toList(),
      );

      _nativeSafetyMonitorStarted = true;
      _nativeSafetyMonitorJourneyId = journey.id;
      _nativeSafetyMonitorCheckAt = journey.estimatedEndTime;
    } catch (_) {
      _nativeSafetyMonitorStarted = false;
      _nativeSafetyMonitorJourneyId = null;
    } finally {
      _nativeSafetyMonitorStarting = false;
    }
  }

  Future<void> _stopNativeSafetyMonitor() async {
    _nativeSafetyMonitorStarted = false;
    _nativeSafetyMonitorStarting = false;
    _nativeSafetyMonitorJourneyId = null;
    _nativeSafetyMonitorCheckAt = null;

    try {
      await widget.emergencyActionService.stopJourneySafetyMonitor();
    } catch (_) {
      // The foreground service is Android-only, so keep non-Android flows moving.
    }
  }

  void _scheduleSafetyEscalations(Journey journey) {
    _safetyMessageTimer?.cancel();
    _safetyCallTimer?.cancel();

    _safetyMessageTimer = Timer(
      _messageEscalationDelay,
      () => unawaited(_handleMessageEscalation(journey)),
    );
    _safetyCallTimer = Timer(
      _callEscalationDelay,
      () => unawaited(_handleCallEscalation()),
    );
  }

  void _runMissedSafetyEscalations() {
    if (_nativeSafetyMonitorStarted) {
      return;
    }

    final shownAt = _safetyCheckShownAt;
    final journey = _safetyCheckJourney;
    if (shownAt == null || journey == null) {
      return;
    }

    final elapsed = DateTime.now().difference(shownAt);
    if (elapsed >= _messageEscalationDelay && !_messageEscalationHandled) {
      unawaited(_handleMessageEscalation(journey));
    }
    if (elapsed >= _callEscalationDelay && !_callEscalationHandled) {
      unawaited(_handleCallEscalation());
    }
  }

  void _cancelSafetyEscalations() {
    _safetyMessageTimer?.cancel();
    _safetyCallTimer?.cancel();
    _safetyMessageTimer = null;
    _safetyCallTimer = null;
  }

  Future<void> _handleMessageEscalation(Journey journey) async {
    if (_messageEscalationHandled) {
      return;
    }
    _messageEscalationHandled = true;

    try {
      final location = await _sosLocation(journey);
      // Network persistence must not delay the time-critical SMS submission.
      unawaited(widget.sosService
          .createTimerSosAlert(
            location: location,
            journeyId: journey.id,
          )
          .then<void>((_) {})
          .catchError((_) {}));
      unawaited(
        widget.journeyService.markJourneySos(journey.id).catchError((_) {}),
      );

      final contact = await widget.emergencyContactService
          .getPrimaryActiveEmergencyContact();
      if (contact == null) {
        _showEscalationSnack(_loc.journeyTimerNoContactFound);
        return;
      }

      final contacts =
          await widget.emergencyContactService.watchEmergencyContacts().first;
      var submitted = 0;
      final seen = <String>{};
      for (final recipient in contacts.where((c) => c.isActive)) {
        if (!seen.add(_normalizedPhone(recipient.phone))) continue;
        try {
          await _sendDirectSms(recipient, journey, location);
          submitted++;
        } catch (_) {/* Continue with the remaining recipients. */}
      }
      _showEscalationSnack(_loc.journeyTimerSmsSubmitted(submitted));
    } catch (_) {
      _showEscalationSnack(_loc.journeyTimerMessagePrepFailed);
    }
  }

  Future<void> _handleCallEscalation() async {
    if (_callEscalationHandled) {
      return;
    }
    _callEscalationHandled = true;

    try {
      final contact = await widget.emergencyContactService
          .getPrimaryActiveEmergencyContact();
      if (contact == null) {
        _showEscalationSnack(_loc.journeyTimerNoContactFoundCall);
        return;
      }

      await _startDirectPhoneCall(contact);
      _showEscalationSnack(_loc.journeyTimerCalling(contact.name));
    } catch (_) {
      _showEscalationSnack(_loc.journeyTimerCallOpenFailed);
    }
  }

  Future<void> _sendDirectSms(
    EmergencyContact contact,
    Journey journey,
    LocationDataModel location,
  ) async {
    await widget.emergencyActionService.sendEmergencySms(
      phone: _normalizedPhone(contact.phone),
      message: _buildEmergencyMessage(journey, location),
    );
  }

  Future<void> _startDirectPhoneCall(EmergencyContact contact) async {
    await widget.emergencyActionService.startEmergencyCall(
      phone: _normalizedPhone(contact.phone),
    );
  }

  String _normalizedPhone(String phone) {
    return phone.replaceAll(RegExp(r'\s+'), '');
  }

  String _buildEmergencyMessage(
    Journey journey,
    LocationDataModel? location,
  ) {
    final locationText = location == null
        ? _loc.journeyTimerEmergencyLocationUnavailable
        : _loc.journeyTimerEmergencyLocationLine(
            'https://maps.google.com/?q=${location.latitude},'
            '${location.longitude}');

    final vehiclePlate = journey.metadata['vehiclePlate'];
    final vehicleText = vehiclePlate is String
        ? '${_loc.journeyTimerEmergencyVehicleLine(vehiclePlate)} '
        : '';
    final destinationText =
        _loc.journeyTimerEmergencyDestinationLine(journey.destinationName);

    return '${_loc.journeyTimerEmergencyAlertIntro} '
        '$vehicleText$destinationText $locationText';
  }

  void _showEscalationSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return _loc.journeyTimerStatusActive;
      case 'safe':
        return _loc.journeyTimerStatusSafe;
      case 'sos':
        return _loc.journeyTimerStatusSos;
      default:
        return status.toUpperCase();
    }
  }

  // ---------------------------------------------------------------------------
  // Pause / resume
  // ---------------------------------------------------------------------------

  static const List<int> _pauseChoicesMinutes = [5, 10, 15, 20, 30, 45, 60];
  static const int _defaultPauseMinutes = 15;

  Future<void> _pauseJourney(Journey journey) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _PauseDurationSheet(
        choicesMinutes: _pauseChoicesMinutes,
        initialMinutes: _defaultPauseMinutes,
      ),
    );
    if (minutes == null || !mounted) {
      return;
    }

    setState(() => _isPausing = true);
    try {
      await widget.journeyService
          .pauseJourney(journey, Duration(minutes: minutes));
      _showEscalationSnack(_loc.journeyTimerPausedFor(minutes));
    } on JourneyServiceException catch (error) {
      _showEscalationSnack(error.message);
    } catch (_) {
      _showEscalationSnack(_loc.journeyTimerPauseFailed);
    } finally {
      if (mounted) {
        setState(() => _isPausing = false);
      }
    }
  }

  Future<void> _resumeJourney(Journey journey) async {
    setState(() => _isPausing = true);
    try {
      await widget.journeyService.resumeJourney(journey);
      _showEscalationSnack(_loc.journeyTimerResumed);
    } catch (_) {
      _showEscalationSnack(_loc.journeyTimerResumeFailed);
    } finally {
      if (mounted) {
        setState(() => _isPausing = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Route
  // ---------------------------------------------------------------------------

  /// The route saved with the journey, or one fetched here for journeys
  /// started before routes were saved (or when the fetch failed at start).
  JourneyRoute? _routeFor(Journey journey) {
    final saved = journey.suggestedRoute;
    if (saved != null) {
      return saved;
    }
    if (!_fallbackRouteRequested) {
      _fallbackRouteRequested = true;
      unawaited(_fetchFallbackRoute(journey));
    }
    return _fallbackRoute;
  }

  Future<void> _fetchFallbackRoute(Journey journey) async {
    final origin = journey.currentLocation ?? journey.startLocation;
    final destination = journey.destinationLocation;
    if (origin == null || destination == null) {
      return;
    }
    final route = await widget.routeService.fetchRoute(
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
      mode: routeModeForJourneyType(journey.journeyType),
    );
    if (mounted && route != null) {
      setState(() => _fallbackRoute = route);
    }
  }

  Future<void> _openInGoogleMaps(Journey journey) async {
    final destination = journey.destinationLocation;
    if (destination == null) {
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelmode': journey.journeyType == 'walk' ? 'walking' : 'driving',
    });
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No maps app or browser: nothing useful to do beyond staying here.
    }
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  static const double _sheetInitialSize = 0.42;
  static const double _sheetMinSize = 0.2;
  static const double _sheetMaxSize = 0.9;

  @override
  Widget build(BuildContext context) {
    final journey = _journey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        title: Text(_loc.journeyTimerTitle),
      ),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(child: _buildBody(context, journey)),
    );
  }

  Widget _buildBody(BuildContext context, Journey? journey) {
    if (_isLoadingJourney) {
      return SafeArea(child: LoadingView(message: _loc.journeyTimerLoading));
    }

    final error = _journeyError;
    if (error != null) {
      return SafeArea(
        child: Center(
            child: Text(_loc.journeyTimerLoadError(error.toString()))),
      );
    }

    if (journey == null) {
      return SafeArea(
        child: Center(child: Text(_loc.journeyTimerNoActiveJourney)),
      );
    }

    final mapLocation = journey.currentLocation ?? journey.startLocation;
    final destinationLocation = journey.destinationLocation;
    final route = _routeFor(journey);
    final c = Theme.of(context).amica;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = constraints.maxHeight * _sheetInitialSize;
        return Stack(
          children: [
            Positioned.fill(
              child: mapLocation == null
                  ? const SizedBox.shrink()
                  : AmicaMapView(
                      latitude: mapLocation.latitude,
                      longitude: mapLocation.longitude,
                      height: null,
                      borderRadius: 0,
                      markerTitle: _loc.journeyTimerMapMarkerTitle,
                      destinationLatitude: destinationLocation?.latitude,
                      destinationLongitude: destinationLocation?.longitude,
                      destinationTitle: journey.destinationName,
                      routePoints: route?.points ?? const [],
                      showMyLocation: true,
                      mapPadding: EdgeInsets.only(
                        top: topInset,
                        bottom: bottomInset,
                      ),
                    ),
            ),
            // Keeps the app bar title readable over any part of the map.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.shell.withValues(alpha: 0.92),
                        c.shell.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: _sheetInitialSize,
              minChildSize: _sheetMinSize,
              maxChildSize: _sheetMaxSize,
              snap: true,
              snapSizes: const [_sheetInitialSize],
              builder: (context, scrollController) => _buildSheet(
                context,
                journey,
                route,
                scrollController,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    Journey journey,
    JourneyRoute? route,
    ScrollController scrollController,
  ) {
    final c = Theme.of(context).amica;
    final textTheme = Theme.of(context).textTheme;
    final isPaused = journey.isPausedAt(DateTime.now());
    final statusColor = switch (journey.status) {
      'sos' => c.terracotta,
      _ when isPaused => c.gold,
      _ => c.sage,
    };
    final statusText =
        isPaused ? _loc.journeyTimerPaused : _statusLabel(journey.status);
    final vehiclePlate = journey.metadata['vehiclePlate'];

    return JourneyGlassSheet(
      scrollController: scrollController,
      children: [
            // Destination + status.
            Row(
              children: [
                GradientIconBadge(icon: journeyTypeIcon(journey.journeyType)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.destinationName,
                        style: textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (vehiclePlate is String)
                        Text(
                          _loc.startJourneyVehicleLabel(vehiclePlate),
                          style: textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusChip(label: statusText, color: statusColor),
              ],
            ),
            const SizedBox(height: 16),
            // Countdown with pause / resume beside it.
            AmicaCard(
              borderColor: isPaused ? c.gold : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loc.journeyTimerTimeRemaining,
                          style: textTheme.bodySmall
                              ?.copyWith(letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<Duration>(
                          valueListenable: _remainingNotifier,
                          builder: (context, remaining, _) => Text(
                            DateTimeUtils.formatDuration(remaining),
                            style: textTheme.displaySmall?.copyWith(
                              fontSize: 40,
                              height: 1.05,
                              color: isPaused ? c.plum45 : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<Duration>(
                          valueListenable: _remainingNotifier,
                          builder: (context, remaining, _) {
                            final total =
                                journey.estimatedDurationMinutes * 60;
                            final fraction = total <= 0
                                ? 0.0
                                : (remaining.inSeconds / total)
                                    .clamp(0.0, 1.0);
                            return _TimeLeftBar(
                              fraction: fraction,
                              paused: isPaused,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<Duration?>(
                          valueListenable: _pauseLeftNotifier,
                          builder: (context, pauseLeft, _) {
                            if (pauseLeft == null) {
                              return Text(
                                _loc.journeyTimerEstimatedDuration(
                                    journey.estimatedDurationMinutes),
                                style: textTheme.bodySmall,
                              );
                            }
                            return Text(
                              _loc.journeyTimerResumesIn(
                                DateTimeUtils.formatDuration(pauseLeft),
                              ),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: c.gold),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildPauseButton(journey, isPaused),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Suggested route.
            AmicaCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.alt_route_rounded,
                    size: 38,
                    soft: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_loc.journeyTimerSuggestedRoute,
                            style: textTheme.titleSmall),
                        Text(
                          route == null
                              ? _loc.journeyTimerNoRoute
                              : _loc.journeyTimerRouteInfo(
                                  formatDistance(route.distanceMeters),
                                  (route.durationSeconds / 60).ceil(),
                                ),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _loc.journeyTimerOpenInMaps,
                    color: c.accentInk,
                    icon: const Icon(Icons.navigation_rounded),
                    onPressed: journey.destinationLocation == null
                        ? null
                        : () => _openInGoogleMaps(journey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label:
                  _isSaving ? _loc.journeyTimerSaving : _loc.safetyCheckImSafe,
              icon: Icons.check_circle_rounded,
              onPressed: _isSaving ? null : () => _markSafe(journey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : () => _sendSos(journey),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.terracottaDeep,
                side: BorderSide(color: c.terracotta.withValues(alpha: 0.45)),
              ),
              icon: const Icon(Icons.sos_rounded),
              label: Text(_loc.journeyTimerTriggerTestSos),
            ),
      ],
    );
  }

  /// The app theme sizes buttons with `Size.fromHeight(54)`, i.e. infinite
  /// width, which breaks layout inside a Row. Buttons beside the timer need
  /// a finite size.
  static const Size _compactButtonSize = Size(112, 48);

  Widget _buildPauseButton(Journey journey, bool isPaused) {
    final busy = _isPausing || _isSaving || !journey.isActive;
    if (isPaused) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: _compactButtonSize),
        onPressed: busy ? null : () => _resumeJourney(journey),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(_loc.journeyTimerResumeNow),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: _compactButtonSize),
      onPressed: busy || _remainingNotifier.value == Duration.zero
          ? null
          : () => _pauseJourney(journey),
      icon: const Icon(Icons.pause_rounded),
      label: Text(_loc.journeyTimerPause),
    );
  }
}

/// Time left, as a soft gradient bar. Gold while paused.
class _TimeLeftBar extends StatelessWidget {
  const _TimeLeftBar({required this.fraction, required this.paused});

  final double fraction;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.accentSoft)),
            FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: paused ? c.gold : null,
                  gradient: paused ? null : c.accentGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Lets the user choose how long to pause the safety timer for.
class _PauseDurationSheet extends StatefulWidget {
  const _PauseDurationSheet({
    required this.choicesMinutes,
    required this.initialMinutes,
  });

  final List<int> choicesMinutes;
  final int initialMinutes;

  @override
  State<_PauseDurationSheet> createState() => _PauseDurationSheetState();
}

class _PauseDurationSheetState extends State<_PauseDurationSheet> {
  late int _minutes = widget.initialMinutes;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.journeyTimerPauseSheetTitle, style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(loc.journeyTimerPauseSheetBody, style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in widget.choicesMinutes)
                  ChoiceChip(
                    label: Text(loc.journeyTimerPauseMinutes(minutes)),
                    selected: minutes == _minutes,
                    onSelected: (_) => setState(() => _minutes = minutes),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: loc.journeyTimerPauseConfirm(_minutes),
              icon: Icons.pause_rounded,
              onPressed: () => Navigator.pop(context, _minutes),
            ),
          ],
        ),
      ),
    );
  }
}
