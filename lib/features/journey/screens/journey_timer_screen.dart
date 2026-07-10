import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
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
  });

  final String? journeyId;
  final JourneyService journeyService;
  final LocationService locationService;
  final SosService sosService;
  final EmergencyContactService emergencyContactService;

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
  bool _messageEscalationHandled = false;
  bool _callEscalationHandled = false;

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

  Future<void> _markSafe(Journey journey) async {
    _cancelSafetyEscalations();
    setState(() => _isSaving = true);
    try {
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
    try {
      final location = await _currentOrFallbackLocation(journey);
      final alertId = timerTriggered
          ? await widget.sosService.createTimerSosAlert(
              location: location,
              journeyId: journey.id,
            )
          : await widget.sosService.createManualSosAlert(
              location: location,
              journeyId: journey.id,
            );
      await widget.journeyService.markJourneySos(journey.id);

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
    _scheduleSafetyEscalations(journey);
    unawaited(_vibrateTwiceForSafetyCheck());

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
    await HapticFeedback.vibrate();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await HapticFeedback.vibrate();
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
      final location = await _currentOrFallbackLocation(journey);
      await widget.sosService.createTimerSosAlert(
        location: location,
        journeyId: journey.id,
      );
      await widget.journeyService.markJourneySos(journey.id);

      final contact = await widget.emergencyContactService
          .getPrimaryActiveEmergencyContact();
      if (contact == null) {
        _showEscalationSnack('No active emergency contact found.');
        return;
      }

      await _openSms(contact, journey, location);
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

      await _openPhoneCall(contact);
    } catch (_) {
      _showEscalationSnack('Could not open emergency call.');
    }
  }

  Future<void> _openSms(
    EmergencyContact contact,
    Journey journey,
    LocationDataModel location,
  ) async {
    final message = Uri.encodeComponent(
      'Amica safety alert: I did not respond to my journey safety check. '
      'Destination: ${journey.destinationName}. '
      'Location: https://maps.google.com/?q=${location.latitude},${location.longitude}',
    );
    final uri = Uri.parse(
      'sms:${_normalizedPhone(contact.phone)}?body=$message',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const FormatException('SMS app not available');
    }
  }

  Future<void> _openPhoneCall(EmergencyContact contact) async {
    final uri = Uri(scheme: 'tel', path: _normalizedPhone(contact.phone));
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw const FormatException('Phone app not available');
    }
  }

  String _normalizedPhone(String phone) {
    return phone.replaceAll(RegExp(r'\s+'), '');
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
      appBar: AppBar(title: const Text('Journey Timer')),
      body: _buildBody(context, journey),
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          journey.destinationName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Status: ${journey.status}'),
        Text('Estimated duration: ${journey.estimatedDurationMinutes} minutes'),
        const SizedBox(height: 16),
        const Text('Time remaining'),
        const SizedBox(height: 8),
        ValueListenableBuilder<Duration>(
          valueListenable: _remainingNotifier,
          builder: (context, remaining, _) {
            return Text(
              DateTimeUtils.formatDuration(remaining),
              style: Theme.of(context).textTheme.displaySmall,
            );
          },
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
          icon: Icons.check_circle,
          onPressed: _isSaving ? null : () => _markSafe(journey),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _sendSos(journey),
          icon: const Icon(Icons.sos),
          label: const Text('Trigger test SOS'),
        ),
      ],
    );
  }
}
