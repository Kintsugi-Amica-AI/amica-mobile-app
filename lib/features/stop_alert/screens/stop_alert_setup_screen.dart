import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/emergency_action_service.dart';
import '../../../services/location_service.dart';
import '../../../services/transit_plan_service.dart';
import '../../journey/widgets/journey_visuals.dart';
import '../../journey/widgets/transit_trip_card.dart';
import '../../journey/models/journey.dart';
import '../../journey/models/location_data_model.dart';
import '../../journey/services/journey_service.dart';
import '../services/route_distance_service.dart';
import '../services/stop_alert_calculator.dart';
import 'stop_alert_active_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Where a rider picks the stop they want to get off at before boarding.
class StopAlertSetupScreen extends StatefulWidget {
  const StopAlertSetupScreen({
    super.key,
    this.locationService = const LocationService(),
    this.journeyService = const JourneyService(),
    this.emergencyActionService = const EmergencyActionService(),
    this.calculator = const StopAlertCalculator(),
    this.routeDistanceService = const RouteDistanceService(),
    this.transitService = const TransitPlanService(),
  });

  final LocationService locationService;
  final JourneyService journeyService;
  final EmergencyActionService emergencyActionService;
  final StopAlertCalculator calculator;
  final RouteDistanceService routeDistanceService;
  final TransitPlanService transitService;

  @override
  State<StopAlertSetupScreen> createState() => _StopAlertSetupScreenState();
}

class _StopAlertSetupScreenState extends State<StopAlertSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dropOffController = TextEditingController();

  Timer? _dropOffSearchDebounce;
  Timer? _routeEstimateDebounce;
  int _dropOffSearchToken = 0;
  int _routeEstimateToken = 0;
  RouteEstimate? _routeEstimate;
  bool _isEstimatingRoute = false;
  LocationDataModel? _currentLocation;
  LocationDataModel? _dropOffLocation;
  int _alertDistanceMeters = Journey.defaultAlertDistanceMeters;
  bool _isLoadingLocation = false;
  bool _isResolvingDropOff = false;
  bool _isStartingRide = false;
  String? _dropOffStatus;
  String? _errorMessage;
  late AppLocalizations _loc;

  /// `bus` or `train`.
  String _mode = 'bus';

  // Trip plan: the stop to get on at, the stop to get OFF at (what the
  // alarm is for), and the walks either side.
  TransitPlan? _plan;
  List<MapRouteLeg> _planLegs = const [];
  bool _isLoadingPlan = false;
  TransitPlanUnavailable? _planUnavailable;
  int _planToken = 0;
  String? _boardStopId;
  String? _alightStopId;

  /// Where the alarm counts down to: the suggested get-off stop when there
  /// is a plan, otherwise the place she typed or pinned.
  LocationDataModel? get _alarmTarget {
    final plan = _plan;
    if (plan != null) {
      return LocationDataModel(
        latitude: plan.alightStop.latitude,
        longitude: plan.alightStop.longitude,
        address: plan.alightStop.name,
        updatedAt: DateTime.now(),
      );
    }
    return _dropOffLocation;
  }

  bool get _isBusy => _isLoadingLocation || _isStartingRide;

  @override
  void initState() {
    super.initState();
    _dropOffController.addListener(_onDropOffTextChanged);
    unawaited(_getCurrentLocation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
  }

  @override
  void dispose() {
    _dropOffSearchDebounce?.cancel();
    _routeEstimateDebounce?.cancel();
    _dropOffController
      ..removeListener(_onDropOffTextChanged)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Picking the drop-off
  // ---------------------------------------------------------------------

  void _onDropOffTextChanged() {
    final dropOffName = _dropOffController.text.trim();

    if (_dropOffLocation != null) {
      _dropOffLocation = _dropOffLocation!.copyWith(
        address: dropOffName,
        updatedAt: DateTime.now(),
      );
    }

    _scheduleDropOffLookup(dropOffName);
  }

  /// The ✕ on the destination field: drops the text, the pin, the trip plan
  /// and the road-distance estimate together.
  void _clearDropOff() {
    _dropOffSearchDebounce?.cancel();
    _dropOffSearchToken++;
    _dropOffController.clear();
    setState(() {
      _dropOffLocation = null;
      _dropOffStatus = null;
      _isResolvingDropOff = false;
      _errorMessage = null;
      _boardStopId = null;
      _alightStopId = null;
    });
    // With no destination this clears the plan and the route estimate.
    _schedulePlan();
  }

  void _scheduleDropOffLookup(String dropOffName) {
    _dropOffSearchDebounce?.cancel();

    if (dropOffName.length < 3) {
      _dropOffSearchToken++;
      if (mounted) {
        setState(() {
          _dropOffStatus = null;
          _isResolvingDropOff = false;
        });
      }
      return;
    }

    final searchToken = ++_dropOffSearchToken;
    _dropOffSearchDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _findDropOffOnMap(dropOffName, searchToken),
    );
  }

  Future<void> _findDropOffOnMap(String dropOffName, int searchToken) async {
    if (!mounted || dropOffName != _dropOffController.text.trim()) {
      return;
    }

    setState(() {
      _isResolvingDropOff = true;
      _dropOffStatus = _loc.stopAlertSetupFindingStop;
      _errorMessage = null;
    });

    try {
      final matches = await geocoding
          .locationFromAddress(dropOffName)
          .timeout(const Duration(seconds: 6));
      if (matches.isEmpty) {
        throw const FormatException('No stop found');
      }

      final match = matches.first;
      if (!mounted || searchToken != _dropOffSearchToken) {
        return;
      }

      setState(() {
        _dropOffLocation = LocationDataModel(
          latitude: match.latitude,
          longitude: match.longitude,
          address: dropOffName,
          updatedAt: DateTime.now(),
        );
        _dropOffStatus = _loc.stopAlertSetupStopFound;
      });
      _schedulePlan();
    } catch (_) {
      if (mounted && searchToken == _dropOffSearchToken) {
        setState(() {
          _dropOffStatus = _loc.stopAlertSetupStopNotFound;
        });
      }
    } finally {
      if (mounted && searchToken == _dropOffSearchToken) {
        setState(() => _isResolvingDropOff = false);
      }
    }
  }

  void _pinDropOff(double latitude, double longitude) {
    _dropOffSearchDebounce?.cancel();
    _dropOffSearchToken++;
    setState(() {
      _dropOffLocation = LocationDataModel(
        latitude: latitude,
        longitude: longitude,
        address: _dropOffController.text.trim(),
        updatedAt: DateTime.now(),
      );
      _dropOffStatus = _loc.stopAlertSetupStopPinned;
      _isResolvingDropOff = false;
      _errorMessage = null;
    });
    _schedulePlan();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final location = await widget.locationService.getCurrentLocationData();
      if (mounted) {
        setState(() => _currentLocation = location);
        _schedulePlan();
      }
    } on LocationServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = _loc.stopAlertSetupLocationError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Starting the ride
  // ---------------------------------------------------------------------

  /// Straight-line distance from where the rider is now to the stop they
  /// picked, or null until both are known.
  double? get _straightLineToDropOff {
    final start = _currentLocation;
    final dropOff = _alarmTarget;
    if (start == null || dropOff == null) {
      return null;
    }
    return widget.calculator.distanceInMeters(
      start.latitude,
      start.longitude,
      dropOff.latitude,
      dropOff.longitude,
    );
  }

  /// Distance the rider actually has to travel: road distance when the backend
  /// could resolve it, straight-line otherwise.
  double? get _distanceToDropOff {
    final roadDistance = _routeEstimate?.roadDistanceMeters;
    if (roadDistance != null) {
      return roadDistance;
    }
    return _straightLineToDropOff;
  }

  /// True when the stop is already inside the alert radius, which would make
  /// the alarm sound the moment the ride starts.
  bool get _alertDistanceTooLarge {
    final distance = _distanceToDropOff;
    if (distance == null) {
      return false;
    }
    return widget.calculator.isAlreadyWithinAlertDistance(
      distanceMeters: distance,
      alertDistanceMeters: _alertDistanceMeters,
    );
  }

  /// Looks up road distance once the rider and their stop are both known.
  ///
  /// Debounced so dragging a pin around the map does not fire a lookup per
  /// frame, and token-guarded so a slow answer for an old pin cannot overwrite
  /// a newer one.
  /// Plans the trip (stops + walks), then measures road distance to the
  /// get-off stop it chose.
  void _schedulePlan() {
    final start = _currentLocation;
    final destination = _dropOffLocation;
    final token = ++_planToken;
    if (start == null || destination == null) {
      setState(() {
        _plan = null;
        _planLegs = const [];
        _isLoadingPlan = false;
        _planUnavailable = null;
      });
      _scheduleRouteEstimate();
      return;
    }
    setState(() {
      _isLoadingPlan = true;
      _planUnavailable = null;
    });
    unawaited(() async {
      final result = await widget.transitService.fetchPlan(
        originLatitude: start.latitude,
        originLongitude: start.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        mode: _mode,
        boardStopId: _boardStopId,
        alightStopId: _alightStopId,
      );
      if (!mounted || token != _planToken) return;
      setState(() {
        _plan = result.plan;
        _planLegs = result.plan == null ? const [] : mapLegsFor(result.plan!);
        _planUnavailable = result.unavailable;
        _isLoadingPlan = false;
      });
      _scheduleRouteEstimate();
    }());
  }

  void _chooseStop(String stopId) {
    final plan = _plan;
    if (plan == null) return;
    if (plan.boardCandidates.any((s) => s.id == stopId)) {
      _boardStopId = stopId;
    } else if (plan.alightCandidates.any((s) => s.id == stopId)) {
      _alightStopId = stopId;
    } else {
      return;
    }
    _schedulePlan();
  }

  void _setMode(String mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _boardStopId = null;
    _alightStopId = null;
    _schedulePlan();
  }

  void _scheduleRouteEstimate() {
    _routeEstimateDebounce?.cancel();
    final start = _currentLocation;
    final dropOff = _alarmTarget;

    if (start == null || dropOff == null) {
      _routeEstimateToken++;
      if (mounted) {
        setState(() {
          _routeEstimate = null;
          _isEstimatingRoute = false;
        });
      }
      return;
    }

    final token = ++_routeEstimateToken;
    _routeEstimateDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _refreshRouteEstimate(token, start, dropOff),
    );
  }

  Future<void> _refreshRouteEstimate(
    int token,
    LocationDataModel start,
    LocationDataModel dropOff,
  ) async {
    if (!mounted || token != _routeEstimateToken) {
      return;
    }
    setState(() => _isEstimatingRoute = true);

    final estimate = await widget.routeDistanceService.estimate(
      originLatitude: start.latitude,
      originLongitude: start.longitude,
      destinationLatitude: dropOff.latitude,
      destinationLongitude: dropOff.longitude,
    );

    if (!mounted || token != _routeEstimateToken) {
      return;
    }
    setState(() {
      _routeEstimate = estimate;
      _isEstimatingRoute = false;
    });
  }

  Future<void> _startRide() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startLocation = _currentLocation;
    if (startLocation == null) {
      setState(() => _errorMessage = _loc.stopAlertSetupNeedLocation);
      return;
    }

    final dropOffLocation = _alarmTarget;
    if (dropOffLocation == null) {
      setState(() => _errorMessage = _loc.stopAlertSetupNeedStop);
      return;
    }
    final plan = _plan;

    setState(() {
      _isStartingRide = true;
      _errorMessage = null;
    });

    final typedName = _dropOffController.text.trim();
    // With a plan, the alarm is for the stop she gets off at; the typed
    // place is where she walks to afterwards.
    final dropOffName = plan?.alightStop.name ?? typedName;

    try {
      final journeyId = await widget.journeyService.startStopAlertRide(
        startLocation: startLocation,
        dropOffLocation: dropOffLocation.copyWith(
          address: dropOffName,
          updatedAt: DateTime.now(),
        ),
        dropOffName: dropOffName,
        alertDistanceMeters: _alertDistanceMeters,
        routeFactor: _routeEstimate?.routeFactor ?? 1,
        routeDistanceMeters: _routeEstimate?.roadDistanceMeters,
        journeyType: _mode,
        transitPlan: plan,
        finalDestinationName: plan == null ? null : typedName,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.stopAlertActive,
        arguments: StopAlertActiveArguments(journeyId: journeyId),
      );
    } on JourneyServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = _loc.stopAlertSetupStartFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingRide = false);
      }
    }
  }

  String? _validateDropOff(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _loc.stopAlertSetupValidateDropOff;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  static const double _sheetInitialSize = 0.5;
  static const double _sheetMinSize = 0.18;
  static const double _sheetMaxSize = 0.92;

  @override
  Widget build(BuildContext context) {
    final currentLocation = _currentLocation;
    final dropOffLocation = _dropOffLocation;
    final mapCenter = currentLocation ??
        dropOffLocation ??
        LocationDataModel(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'Colombo',
          updatedAt: DateTime.now(),
        );
    final dropOffTitle = _dropOffController.text.trim().isEmpty
        ? _loc.stopAlertSetupYourStopDefault
        : _dropOffController.text.trim();
    final c = Theme.of(context).amica;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    final plan = _plan;

    // Same layout as the Journeys screens: the map fills the screen and a
    // frosted sheet floats over it.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(_loc.stopAlertSetupTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned.fill(
                  child: AmicaMapView(
                    latitude: mapCenter.latitude,
                    longitude: mapCenter.longitude,
                    height: null,
                    borderRadius: 0,
                    markerTitle: _loc.stopAlertSetupYouAreHereMarker,
                    showStartMarker: currentLocation != null,
                    showMyLocation: currentLocation != null,
                    destinationLatitude: dropOffLocation?.latitude,
                    destinationLongitude: dropOffLocation?.longitude,
                    destinationTitle: dropOffTitle,
                    routeLegs: _planLegs,
                    transitStops: plan == null
                        ? const []
                        : mapStopsFor(plan, withCandidates: true),
                    onTransitStopTap: _isStartingRide
                        ? null
                        : (stop) => _chooseStop(stop.id),
                    mapPadding: EdgeInsets.only(
                      top: topInset,
                      bottom: constraints.maxHeight * _sheetInitialSize,
                    ),
                    onTap: _isStartingRide ? null : _pinDropOff,
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
                  initialChildSize: _sheetInitialSize,
                  minChildSize: _sheetMinSize,
                  maxChildSize: _sheetMaxSize,
                  snap: true,
                  snapSizes: const [_sheetInitialSize],
                  builder: (context, scrollController) =>
                      _buildSheet(context, scrollController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(BuildContext context, ScrollController scrollController) {
    final c = Theme.of(context).amica;
    final textTheme = Theme.of(context).textTheme;
    final currentLocation = _currentLocation;
    final dropOffLocation = _dropOffLocation;
    final plan = _plan;

    return JourneyGlassSheet(
      scrollController: scrollController,
      children: [
        Text(_loc.stopAlertSetupHeadline, style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(_loc.stopAlertSetupIntro, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        // Bus or train.
        Row(
          children: [
            JourneyTypeChip(
              type: 'bus',
              label: _loc.startJourneyTypeBus,
              selected: _mode == 'bus',
              onTap: _isBusy ? null : () => _setMode('bus'),
            ),
            const SizedBox(width: 8),
            JourneyTypeChip(
              type: 'train',
              label: _loc.startJourneyTypeTrain,
              selected: _mode == 'train',
              onTap: _isBusy ? null : () => _setMode('train'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // From.
        AmicaCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              const GradientIconBadge(icon: Icons.near_me_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_loc.startJourneyYourLocation,
                        style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      currentLocation == null
                          ? (_isLoadingLocation
                              ? _loc.stopAlertSetupGettingLocation
                              : _loc.stopAlertSetupLocationUnavailable)
                          : '${currentLocation.latitude.toStringAsFixed(5)}, '
                              '${currentLocation.longitude.toStringAsFixed(5)}',
                      style: textTheme.bodySmall?.copyWith(color: c.plum45),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _loc.stopAlertSetupUpdateLocation,
                onPressed: _isBusy ? null : _getCurrentLocation,
                color: c.accentInk,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // To.
        CustomTextField(
          label: _loc.stopAlertWhereGoing,
          controller: _dropOffController,
          prefixIcon: Icons.favorite_border_rounded,
          enabled: !_isStartingRide,
          onClear: _clearDropOff,
          validator: _validateDropOff,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              dropOffLocation == null
                  ? Icons.touch_app_outlined
                  : Icons.place_rounded,
              size: 15,
              color: c.plum45,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isResolvingDropOff
                    ? _loc.stopAlertSetupFindingStop
                    : _dropOffStatus ??
                        (dropOffLocation == null
                            ? _loc.stopAlertSetupTapToPin
                            : _loc.stopAlertSetupStopPinnedAt(
                                dropOffLocation.latitude.toStringAsFixed(5),
                                dropOffLocation.longitude.toStringAsFixed(5),
                              )),
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (dropOffLocation != null) ...[
          const SizedBox(height: 12),
          TransitTripCard(
            mode: _mode,
            plan: plan,
            isLoading: _isLoadingPlan,
            unavailable: _planUnavailable,
            onChooseBoard:
                _isStartingRide ? null : (stop) => _chooseStop(stop.id),
            onChooseAlight:
                _isStartingRide ? null : (stop) => _chooseStop(stop.id),
          ),
          if (plan != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 16, color: c.accentInk),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _loc.stopAlertWakeBefore(plan.alightStop.name),
                    style: textTheme.bodySmall?.copyWith(color: c.accentInk),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 16),
        _buildAlertDistancePicker(context),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: c.terracottaDeep),
          ),
        ],
        const SizedBox(height: 22),
        PrimaryButton(
          label: _isStartingRide
              ? _loc.startJourneyStarting
              : _loc.stopAlertSetupStartButton,
          icon: Icons.notifications_active_rounded,
          onPressed: (_isBusy || _isResolvingDropOff || _isLoadingPlan)
              ? null
              : _startRide,
        ),
        const SizedBox(height: 14),
        Text(
          _loc.stopAlertSetupKeepNotificationNote,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAlertDistancePicker(BuildContext context) {
    final distance = _distanceToDropOff;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIconBadge(
                icon: Icons.alarm_rounded,
                size: 34,
                soft: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _loc.stopAlertSetupAlertDistanceLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: StopAlertCalculator.alertDistanceOptionsMeters.map(
              (meters) {
                return ChoiceChip(
                  selected: meters == _alertDistanceMeters,
                  label: Text(widget.calculator.formatAlertDistance(meters)),
                  onSelected: _isBusy
                      ? null
                      : (_) => setState(() => _alertDistanceMeters = meters),
                );
              },
            ).toList(),
          ),
          if (_isEstimatingRoute) ...[
            const SizedBox(height: 14),
            Text(
              _loc.stopAlertSetupCheckingRoadDistance,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (distance != null) ...[
            const SizedBox(height: 14),
            Text(
              _routeEstimate == null
                  // Said plainly, because it reads shorter than the ride will
                  // actually be.
                  ? _loc.stopAlertSetupDistanceStraightLine(
                      widget.calculator.formatDistance(distance))
                  : _loc.stopAlertSetupDistanceByRoad(
                      widget.calculator.formatDistance(distance)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_alertDistanceTooLarge) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).amica.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _loc.stopAlertSetupTooClose(
                      widget.calculator
                          .formatAlertDistance(_alertDistanceMeters),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).amica.gold,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
