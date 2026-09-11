import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/emergency_action_service.dart';
import '../../../services/location_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../models/journey.dart';
import '../models/location_data_model.dart';
import '../services/journey_service.dart';

class JourneyTimerScreen extends StatefulWidget {
  const JourneyTimerScreen({
    super.key,
    this.journeyId,
    this.journeyService = const JourneyService(),
    this.locationService = const LocationService(),
    this.sosService = const SosService(),
    this.emergencyContactService = const EmergencyContactService(),
    this.emergencyActionService = const EmergencyActionService(),
  });

  final String? journeyId;
  final JourneyService journeyService;
  final LocationService locationService;
  final SosService sosService;
  final EmergencyContactService emergencyContactService;
  final EmergencyActionService emergencyActionService;

  @override
  State<JourneyTimerScreen> createState() => _JourneyTimerScreenState();
}

class _JourneyTimerScreenState extends State<JourneyTimerScreen>
    with WidgetsBindingObserver {
  final ValueNotifier<Duration> _remainingNotifier =
      ValueNotifier<Duration>(Duration.zero);

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
    super.dispose();
  }

  void _listenToJourney() {
    _journeySubscription = _journeyStream().listen(
      (journey) {
        if (!mounted) {
          return;
        }
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
    final remaining = journey.estimatedEndTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _updateRemainingAndSafetyState() {
    final journey = _journey;
    if (journey == null || !journey.isActive) {
      return;
    }

    final remaining = _remaining(journey);
    if (_remainingNotifier.value != remaining) {
      _remainingNotifier.value = remaining;
    }

    if (remaining == Duration.zero) {
      _maybeShowSafetyDialog(journey);
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
              (location) =>
                  widget.journeyService.updateCurrentLocation(journey.id, location),
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
        const SnackBar(content: Text('Journey marked safe')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not mark journey safe')),
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
    _showEscalationSnack('Sending SOS alert...');
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
          const SnackBar(content: Text('Could not create SOS alert')),
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
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Are you safe?'),
            content: const Text(
              'Your journey timer has ended. Confirm you are safe or send SOS.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markSafe(journey);
                },
                child: const Text('I am safe'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendSos(journey, timerTriggered: true);
                },
                child: const Text('Send SOS'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _vibrateTwiceForSafetyCheck() async {
    try {
      await widget.emergencyActionService.vibrateTwice();
    } catch (_) {
      // Vibration support varies by emulator/device, so keep the safety flow moving.
    }
  }

  Future<void> _startNativeSafetyMonitorIfNeeded(Journey? journey) async {
    if (journey == null || !journey.isActive) {
      await _stopNativeSafetyMonitor();
      return;
    }

    if (_nativeSafetyMonitorStarting ||
        _nativeSafetyMonitorJourneyId == journey.id) {
      return;
    }

    _nativeSafetyMonitorStarting = true;
    try {
      await widget.emergencyActionService.prepareEmergencyPermissions();

      final contact = await widget.emergencyContactService
          .getPrimaryActiveEmergencyContact();
      final location = journey.currentLocation ?? journey.startLocation;

      await widget.emergencyActionService.startJourneySafetyMonitor(
        journeyId: journey.id,
        destinationName: journey.destinationName,
        safetyCheckAt: journey.estimatedEndTime,
        emergencyPhone: contact == null ? '' : _normalizedPhone(contact.phone),
        emergencyMessage: _buildEmergencyMessage(journey, location),
      );

      _nativeSafetyMonitorStarted = true;
      _nativeSafetyMonitorJourneyId = journey.id;
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
      const Duration(minutes: 1),
      () => unawaited(_handleMessageEscalation(journey)),
    );
    _safetyCallTimer = Timer(
      const Duration(minutes: 3),
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
    if (elapsed >= const Duration(minutes: 1) &&
        !_messageEscalationHandled) {
      unawaited(_handleMessageEscalation(journey));
    }
    if (elapsed >= const Duration(minutes: 3) && !_callEscalationHandled) {
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
      await widget.sosService.createTimerSosAlert(
        location: location,
        journeyId: journey.id,
      );
      unawaited(
        widget.journeyService.markJourneySos(journey.id).catchError((_) {}),
      );

      final contact = await widget.emergencyContactService
          .getPrimaryActiveEmergencyContact();
      if (contact == null) {
        _showEscalationSnack('No active emergency contact found.');
        return;
      }

      await _sendDirectSms(contact, journey, location);
      _showEscalationSnack('Emergency SMS sent to ${contact.name}.');
    } catch (_) {
      _showEscalationSnack('Could not prepare emergency message.');
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
        _showEscalationSnack('No active emergency contact found for call.');
        return;
      }

      await _startDirectPhoneCall(contact);
      _showEscalationSnack('Calling ${contact.name}.');
    } catch (_) {
      _showEscalationSnack('Could not open emergency call.');
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
        ? 'Location not available.'
        : 'Location: https://maps.google.com/?q=${location.latitude},'
            '${location.longitude}';

    return 'Amica safety alert: I did not respond to my journey safety check. '
        'Destination: ${journey.destinationName}. $locationText';
  }

  void _showEscalationSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journey = _journey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Journey Timer')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(child: SafeArea(child: _buildBody(context, journey))),
    );
  }

  Widget _buildBody(BuildContext context, Journey? journey) {
    if (_isLoadingJourney) {
      return const LoadingView(message: 'Loading journey');
    }

    final error = _journeyError;
    if (error != null) {
      return Center(child: Text('Could not load journey: $error'));
    }

    if (journey == null) {
      return const Center(child: Text('No active journey found.'));
    }

    final mapLocation = journey.currentLocation ?? journey.startLocation;
    final destinationLocation = journey.destinationLocation;
    final statusColor = switch (journey.status) {
      'sos' => AppColors.alert,
      'safe' => AppColors.success,
      _ => AppColors.secondary,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                journey.destinationName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                journey.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Estimated duration: ${journey.estimatedDurationMinutes} minutes'),
        const SizedBox(height: 20),
        GlassCard(
          child: Column(
            children: [
              Text(
                'TIME REMAINING',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.4,
                    ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Duration>(
                valueListenable: _remainingNotifier,
                builder: (context, remaining, _) {
                  return ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryButtonGradient.createShader(bounds),
                    child: Text(
                      DateTimeUtils.formatDuration(remaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (mapLocation != null) ...[
          const SizedBox(height: 20),
          AmicaMapView(
            latitude: mapLocation.latitude,
            longitude: mapLocation.longitude,
            markerTitle: 'Journey location',
            destinationLatitude: destinationLocation?.latitude,
            destinationLongitude: destinationLocation?.longitude,
            destinationTitle: journey.destinationName,
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: _isSaving ? 'Saving...' : 'I am safe',
          icon: Icons.check_circle_rounded,
          onPressed: _isSaving ? null : () => _markSafe(journey),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _sendSos(journey),
          icon: const Icon(Icons.sos_rounded),
          label: const Text('Trigger test SOS'),
        ),
      ],
    );
  }
}
