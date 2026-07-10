import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/location_service.dart';
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
  });

  final String? journeyId;
  final JourneyService journeyService;
  final LocationService locationService;
  final SosService sosService;

  @override
  State<JourneyTimerScreen> createState() => _JourneyTimerScreenState();
}

class _JourneyTimerScreenState extends State<JourneyTimerScreen> {
  Timer? _timer;
  bool _isSaving = false;
  bool _safetyDialogShown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
    if (_safetyDialogShown || _remaining(journey) != Duration.zero) {
      return;
    }

    _safetyDialogShown = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Journey Timer')),
      body: StreamBuilder<Journey?>(
        stream: _journeyStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading journey');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load journey: ${snapshot.error}'));
          }

          final journey = snapshot.data;
          if (journey == null) {
            return const Center(child: Text('No active journey found.'));
          }

          _maybeShowSafetyDialog(journey);
          final remaining = _remaining(journey);
          final mapLocation = journey.currentLocation ?? journey.startLocation;

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
              Text(
                DateTimeUtils.formatDuration(remaining),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              if (mapLocation != null) ...[
                const SizedBox(height: 20),
                AmicaMapView(
                  latitude: mapLocation.latitude,
                  longitude: mapLocation.longitude,
                  markerTitle: 'Journey location',
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
        },
      ),
    );
  }
}
