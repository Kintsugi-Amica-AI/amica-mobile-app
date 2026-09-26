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
import '../../journey/widgets/journey_visuals.dart';
import '../../journey/widgets/transit_trip_card.dart';
import '../../../services/transit_plan_service.dart';
import '../services/stop_alert_calculator.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/services/notification_inbox_service.dart';
import '../../../l10n/generated/app_localizations.dart';

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
  late AppLocalizations _loc;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
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
          _locationError = _loc.stopAlertActiveLocationPaused;
        });
      },
    );
  }

  /// Distance from the drop-off, recomputed whenever either the ride or the
  /// rider's position changes.
  void _recomputeDistance() {
    final ride = _ride;
    final dropOff = ride?.stopAlertTarget;
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

    // The device measures a straight line, but the rider asked to be warned a
    // road distance before their stop, so the threshold is converted with the
    // route factor resolved when the ride started.
    if (widget.calculator.shouldAlert(
      distanceMeters: distance,
      alertDistanceMeters: widget.calculator
          .straightLineThresholdMeters(
            alertDistanceMeters: ride.alertDistanceMeters,
            routeFactor: ride.routeFactor,
          )
          .round(),
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
      // The native service records its own alarm in the Notifications list;
      // when it never started, record it from here.
      unawaited(NotificationInboxService.instance.add(AppNotification(
        id: '${DateTime.now().microsecondsSinceEpoch}-stop_alert',
        type: 'stop_alert',
        title: _loc.stopAlertActiveComingUp,
        body: _loc.stopAlertActiveGetReady(ride.stopAlertTargetName),
        receivedAt: DateTime.now(),
      )));
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

    final dropOff = ride.stopAlertTarget;
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
        dropOffName: ride.stopAlertTargetName,
        alertDistanceMeters: ride.alertDistanceMeters,
        routeFactor: ride.routeFactor,
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
          SnackBar(content: Text(_loc.stopAlertActiveCloseFailed)),
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
      appBar: AppBar(title: Text(_loc.stopAlertSetupTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoadingRide) {
      return SafeArea(
        child: LoadingView(message: _loc.stopAlertActiveLoading),
      );
    }

    final error = _rideError;
    if (error != null) {
      return SafeArea(
        child: Center(
            child: Text(_loc.stopAlertActiveLoadError(error.toString()))),
      );
    }

    final ride = _ride;
    if (ride == null) {
      return SafeArea(child: Center(child: Text(_loc.stopAlertActiveNoRide)));
    }

    final dropOff = ride.stopAlertTarget;
    final mapLocation = _currentLocation ?? ride.currentLocation ?? ride.startLocation;

    final plan = ride.transitPlan;
    final c = Theme.of(context).amica;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    // Same layout as the Journeys screens: full-screen map, frosted sheet.
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          if (mapLocation != null)
            Positioned.fill(
              child: AmicaMapView(
                latitude: mapLocation.latitude,
                longitude: mapLocation.longitude,
                height: null,
                borderRadius: 0,
                showMyLocation: true,
                markerTitle: _loc.stopAlertSetupYouAreHereMarker,
                destinationLatitude: dropOff?.latitude,
                destinationLongitude: dropOff?.longitude,
                destinationTitle: ride.stopAlertTargetName,
                routeLegs: plan == null ? const [] : _legsFor(plan),
                transitStops: plan == null ? const [] : mapStopsFor(plan),
                mapPadding: EdgeInsets.only(
                  top: topInset,
                  bottom: constraints.maxHeight * 0.5,
                ),
              ),
            ),
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
            initialChildSize: 0.5,
            minChildSize: 0.22,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.5],
            builder: (context, scrollController) => JourneyGlassSheet(
              scrollController: scrollController,
              children: [
                _buildDistanceCard(context, ride),
                if (plan != null) ...[
                  const SizedBox(height: 12),
                  TransitTripCard(mode: plan.mode, plan: plan),
                ],
                const SizedBox(height: 12),
                AmicaCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: _loc.stopAlertActiveGettingOffAt,
                        value: ride.stopAlertTargetName,
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        label: _loc.stopAlertActiveAlertDistance,
                        value: widget.calculator.formatAlertDistance(
                          ride.alertDistanceMeters,
                        ),
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        label: _loc.stopAlertActiveBackgroundAlarm,
                        value: _nativeMonitorStarted
                            ? _loc.stopAlertActiveStatusActive
                            : _loc.stopAlertActiveStatusAppOnly,
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        label: _loc.stopAlertActiveDistanceMeasured,
                        value: ride.routeFactor > 1
                            ? _loc.stopAlertActiveByRoad
                            : _loc.stopAlertActiveStraightLine,
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
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isEndingRide
                      ? _loc.stopAlertActiveEnding
                      : _loc.stopAlertActiveGetOffButton,
                  icon: Icons.check_circle_rounded,
                  onPressed: _isEndingRide ? null : () => _endRide(ride),
                ),
                const SizedBox(height: 14),
                Text(
                  _nativeMonitorStarted
                      ? _loc.stopAlertActiveCanLockPhone
                      : _loc.stopAlertActiveKeepScreenOpen,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TransitPlan? _cachedPlan;
  List<MapRouteLeg> _cachedLegs = const [];

  /// Keeps the same decoded legs across location ticks, so the map is not
  /// re-framed every time the distance updates.
  List<MapRouteLeg> _legsFor(TransitPlan plan) {
    final cached = _cachedPlan;
    if (cached == null ||
        cached.boardStop.id != plan.boardStop.id ||
        cached.alightStop.id != plan.alightStop.id) {
      _cachedLegs = mapLegsFor(plan);
    }
    _cachedPlan = plan;
    return _cachedLegs;
  }

  Widget _buildDistanceCard(BuildContext context, Journey ride) {
    final distance = _distanceMeters;
    final color =
        _hasAlerted ? Theme.of(context).amica.gold : Theme.of(context).amica.accent;

    return GlassCard(
      borderColor: _hasAlerted ? Theme.of(context).amica.gold : null,
      child: Column(
        children: [
          _buildPulsingIcon(color),
          const SizedBox(height: 16),
          Text(
            _hasAlerted
                ? _loc.stopAlertActiveComingUp
                : _loc.stopAlertActiveDistanceLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.4,
                  color: _hasAlerted ? Theme.of(context).amica.gold : null,
                ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) => Text(
              distance == null
                  ? '--'
                  : widget.calculator.formatDistance(
                      // Shown as road distance so the number matches the
                      // distance the alarm is actually counting down.
                      widget.calculator.estimatedRoadDistanceMeters(
                        straightLineMeters: distance,
                        routeFactor: ride.routeFactor,
                      ),
                    ),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 46,
                    height: 1.05,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _hasAlerted
                ? _loc.stopAlertActiveGetReady(ride.stopAlertTargetName)
                : _loc.stopAlertActiveWillAlarmAt(
                    widget.calculator
                        .formatAlertDistance(ride.alertDistanceMeters)),
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
    final dropOff = ride.stopAlertTarget;
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
        backgroundColor: Theme.of(context).amica.accentSoft,
        valueColor: AlwaysStoppedAnimation<Color>(
          _hasAlerted
              ? Theme.of(context).amica.gold
              : Theme.of(context).amica.accent,
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
            : (_ride?.journeyType == 'train'
                ? Icons.train_rounded
                : Icons.directions_bus_filled_rounded),
        color: _hasAlerted ? color : Theme.of(context).amica.accentInk,
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
                  color: Theme.of(context).amica.plum,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
