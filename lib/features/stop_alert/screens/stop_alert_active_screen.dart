import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/emergency_action_service.dart';
import '../../../services/location_service.dart';
import '../../journey/models/journey.dart';
import '../../journey/models/location_data_model.dart';
import '../../journey/services/journey_service.dart';
import '../services/stop_alert_calculator.dart';

class StopAlertActiveArguments {
  const StopAlertActiveArguments({this.journeyId});

  final String? journeyId;
}

/// Live view of a bus ride: how far the rider still is from their stop, and
/// the alarm when they get close.
///
/// The native [StopAlertMonitorService] is the one that actually has to sound
/// the alarm, since the phone will usually be pocketed. This screen mirrors
/// the same distance rule so the rider sees a live countdown while the app is
/// open, and so the alarm still works if the native monitor could not start.
class StopAlertActiveScreen extends StatefulWidget {
  const StopAlertActiveScreen({
    super.key,
    this.arguments,
    this.journeyService = const JourneyService(),
    this.locationService = const LocationService(),
    this.emergencyActionService = const EmergencyActionService(),
    this.calculator = const StopAlertCalculator(),
  });

  final StopAlertActiveArguments? arguments;
  final JourneyService journeyService;
  final LocationService locationService;
  final EmergencyActionService emergencyActionService;
  final StopAlertCalculator calculator;

  @override
  State<StopAlertActiveScreen> createState() => _StopAlertActiveScreenState();
}

class _StopAlertActiveScreenState extends State<StopAlertActiveScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  StreamSubscription<Journey?>? _journeySubscription;
  StreamSubscription<Position>? _positionSubscription;

  Journey? _ride;
  Object? _rideError;
  LocationDataModel? _currentLocation;
  double? _distanceMeters;
  bool _isLoadingRide = true;
  bool _isEndingRide = false;
  bool _hasAlerted = false;
  bool _nativeMonitorStarted = false;
  bool _nativeMonitorStarting = false;
  String? _nativeMonitorRideId;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _listenToRide();
    _listenToPosition();
  }

  @override
  void dispose() {
    _journeySubscription?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------

  void _listenToRide() {
    _journeySubscription = _rideStream().listen(
      (ride) {
        if (!mounted) {
          return;
        }
        setState(() {
          _ride = ride;
          _rideError = null;
          _isLoadingRide = false;
          if (ride != null && ride.stopAlertTriggered) {
            _hasAlerted = true;
          }
        });
        _recomputeDistance();
        unawaited(_startNativeMonitorIfNeeded(ride));
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _rideError = error;
          _isLoadingRide = false;
        });
      },
    );
  }

  Stream<Journey?> _rideStream() {
    final journeyId = widget.arguments?.journeyId;
    if (journeyId == null || journeyId.isEmpty) {
      return widget.journeyService.watchActiveStopAlertRide();
    }
    return widget.journeyService.watchJourney(journeyId);
  }

  void _listenToPosition() {
    _positionSubscription = widget.locationService.watchPosition().listen(
      (position) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentLocation = LocationDataModel(
            latitude: position.latitude,
            longitude: position.longitude,
            address: '',
            updatedAt: DateTime.now(),
          );
          _locationError = null;
        });
        _recomputeDistance();
      },
      onError: (Object _) {
        if (!mounted) {
          return;
        }
        setState(() {
          _locationError =
              'Live location paused. Amica keeps watching in the background.';
        });
      },
    );
  }

  /// Distance from the drop-off, recomputed whenever either the ride or the
  /// rider's position changes.
  void _recomputeDistance() {
    final ride = _ride;
    final dropOff = ride?.destinationLocation;
    final current = _currentLocation ?? ride?.currentLocation;
    if (ride == null || dropOff == null || current == null) {
      return;
    }

    final distance = widget.calculator.distanceInMeters(
      current.latitude,
      current.longitude,
      dropOff.latitude,
      dropOff.longitude,
    );

    if (mounted) {
      setState(() => _distanceMeters = distance);
    }

    if (widget.calculator.shouldAlert(
      distanceMeters: distance,
      alertDistanceMeters: ride.alertDistanceMeters,
      alreadyAlerted: _hasAlerted,
    )) {
      unawaited(_handleApproachingStop(ride));
    }
  }

  Future<void> _handleApproachingStop(Journey ride) async {
    if (_hasAlerted) {
      return;
    }
    setState(() => _hasAlerted = true);

    // The native monitor owns the audible alarm and the vibration. Only
    // vibrate from here when it never started, so the rider does not get a
    // doubled buzz on the normal path.
    if (!_nativeMonitorStarted) {
      try {
        await widget.emergencyActionService.vibrateTwice();
      } catch (_) {
        // Vibration support varies by device; the on-screen alert still shows.
      }
    }

    try {
      await widget.journeyService.markStopAlertTriggered(ride.id);
    } catch (_) {
      // Recording the alarm is bookkeeping; never let it break the alert.
    }
  }

  Future<void> _startNativeMonitorIfNeeded(Journey? ride) async {
    if (ride == null || !ride.isActive || !ride.isStopAlertRide) {
      return;
    }

    final dropOff = ride.destinationLocation;
    if (dropOff == null) {
      return;
    }

    if (_nativeMonitorStarting || _nativeMonitorRideId == ride.id) {
      return;
    }

    _nativeMonitorStarting = true;
    try {
      await widget.emergencyActionService.prepareNotificationPermission();
      await widget.emergencyActionService.startStopAlertMonitor(
        dropOffLatitude: dropOff.latitude,
        dropOffLongitude: dropOff.longitude,
        dropOffName: ride.destinationName,
        alertDistanceMeters: ride.alertDistanceMeters,
        alreadyAlerted: _hasAlerted,
      );
      _nativeMonitorStarted = true;
      _nativeMonitorRideId = ride.id;
    } catch (_) {
      // Android-only. On other platforms the in-app tracking above still runs
      // while this screen is open.
      _nativeMonitorStarted = false;
      _nativeMonitorRideId = null;
    } finally {
      _nativeMonitorStarting = false;
    }
  }

  Future<void> _endRide(Journey ride) async {
    setState(() => _isEndingRide = true);

    try {
      await widget.emergencyActionService.stopStopAlertMonitor();
    } catch (_) {
      // The foreground service is Android-only.
    }

    try {
      await widget.journeyService.endStopAlertRide(ride.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not close the ride record')),
        );
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Bus stop alert')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(child: _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingRide) {
      return const LoadingView(message: 'Loading your ride');
    }

    final error = _rideError;
    if (error != null) {
      return Center(child: Text('Could not load the ride: $error'));
    }

    final ride = _ride;
    if (ride == null) {
      return const Center(child: Text('No active bus ride found.'));
    }

    final dropOff = ride.destinationLocation;
    final mapLocation = _currentLocation ?? ride.currentLocation ?? ride.startLocation;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildDistanceCard(context, ride),
        const SizedBox(height: 18),
        if (mapLocation != null) ...[
          AmicaMapView(
            latitude: mapLocation.latitude,
            longitude: mapLocation.longitude,
            markerTitle: 'You are here',
            destinationLatitude: dropOff?.latitude,
            destinationLongitude: dropOff?.longitude,
            destinationTitle: ride.destinationName,
          ),
          const SizedBox(height: 18),
        ],
        GlassCard(
          child: Column(
            children: [
              _InfoRow(
                label: 'Getting off at',
                value: ride.destinationName,
              ),
              const Divider(height: 22),
              _InfoRow(
                label: 'Alert distance',
                value: widget.calculator.formatAlertDistance(
                  ride.alertDistanceMeters,
                ),
              ),
              const Divider(height: 22),
              _InfoRow(
                label: 'Background alarm',
                value: _nativeMonitorStarted ? 'Active' : 'App only',
              ),
            ],
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 12),
          Text(
            _locationError!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: _isEndingRide ? 'Ending...' : 'I am getting off here',
          icon: Icons.check_circle_rounded,
          onPressed: _isEndingRide ? null : () => _endRide(ride),
        ),
        const SizedBox(height: 14),
        Text(
          _nativeMonitorStarted
              ? 'You can lock your phone. Amica will alarm before your stop.'
              : 'Keep this screen open so Amica can watch your stop.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDistanceCard(BuildContext context, Journey ride) {
    final distance = _distanceMeters;
    final color = _hasAlerted ? AppColors.warning : AppColors.secondary;

    return GlassCard(
      borderColor: _hasAlerted ? AppColors.warning : null,
      child: Column(
        children: [
          _buildPulsingIcon(color),
          const SizedBox(height: 16),
          Text(
            _hasAlerted ? 'YOUR STOP IS COMING UP' : 'DISTANCE TO YOUR STOP',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.4,
                  color: _hasAlerted ? AppColors.warning : null,
                ),
          ),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryButtonGradient.createShader(bounds),
            child: Text(
              distance == null
                  ? '--'
                  : widget.calculator.formatDistance(distance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasAlerted
                ? 'Get ready to get off at ${ride.destinationName}.'
                : 'Amica will alarm at '
                    '${widget.calculator.formatAlertDistance(ride.alertDistanceMeters)}.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _buildProgressBar(ride),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Journey ride) {
    final start = ride.startLocation;
    final dropOff = ride.destinationLocation;
    final distance = _distanceMeters;

    if (start == null || dropOff == null || distance == null) {
      return const SizedBox.shrink();
    }

    final startDistance = widget.calculator.distanceInMeters(
      start.latitude,
      start.longitude,
      dropOff.latitude,
      dropOff.longitude,
    );
    final progress = widget.calculator.progress(
      startDistanceMeters: startDistance,
      currentDistanceMeters: distance,
    );

    if (progress == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(
          _hasAlerted ? AppColors.warning : AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = _hasAlerted
            ? 20 + (_pulseController.value * 26)
            : 12 + (_pulseController.value * 10);
        return Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: glow,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Icon(
        _hasAlerted
            ? Icons.notifications_active_rounded
            : Icons.directions_bus_filled_rounded,
        color: color,
        size: 38,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
