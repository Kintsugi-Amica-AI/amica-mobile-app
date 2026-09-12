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
import '../../journey/models/journey.dart';
import '../../journey/models/location_data_model.dart';
import '../../journey/services/journey_service.dart';
import '../services/route_distance_service.dart';
import '../services/stop_alert_calculator.dart';
import 'stop_alert_active_screen.dart';

/// Where a rider picks the stop they want to get off at before boarding.
class StopAlertSetupScreen extends StatefulWidget {
  const StopAlertSetupScreen({
    super.key,
    this.locationService = const LocationService(),
    this.journeyService = const JourneyService(),
    this.emergencyActionService = const EmergencyActionService(),
    this.calculator = const StopAlertCalculator(),
    this.routeDistanceService = const RouteDistanceService(),
  });

  final LocationService locationService;
  final JourneyService journeyService;
  final EmergencyActionService emergencyActionService;
  final StopAlertCalculator calculator;
  final RouteDistanceService routeDistanceService;

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

  bool get _isBusy => _isLoadingLocation || _isStartingRide;

  @override
  void initState() {
    super.initState();
    _dropOffController.addListener(_onDropOffTextChanged);
    unawaited(_getCurrentLocation());
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
      _dropOffStatus = 'Finding your stop on the map...';
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
        _dropOffStatus = 'Stop found on the map.';
      });
      _scheduleRouteEstimate();
    } catch (_) {
      if (mounted && searchToken == _dropOffSearchToken) {
        setState(() {
          _dropOffStatus = 'Stop not found. Tap the map to pin it.';
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
      _dropOffStatus = 'Stop pinned on the map.';
      _isResolvingDropOff = false;
      _errorMessage = null;
    });
    _scheduleRouteEstimate();
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
        _scheduleRouteEstimate();
      }
    } on LocationServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not get your current location.');
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
    final dropOff = _dropOffLocation;
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
  void _scheduleRouteEstimate() {
    _routeEstimateDebounce?.cancel();
    final start = _currentLocation;
    final dropOff = _dropOffLocation;

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
      setState(() => _errorMessage = 'Get your current location first.');
      return;
    }

    final dropOffLocation = _dropOffLocation;
    if (dropOffLocation == null) {
      setState(() => _errorMessage = 'Search for your stop or tap the map to pin it.');
      return;
    }

    setState(() {
      _isStartingRide = true;
      _errorMessage = null;
    });

    final dropOffName = _dropOffController.text.trim();

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
        setState(() => _errorMessage = 'Could not start the bus ride.');
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingRide = false);
      }
    }
  }

  String? _validateDropOff(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name your stop so the alert can tell you where you are going';
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

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
        ? 'Your stop'
        : _dropOffController.text.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Bus stop alert')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Never miss your stop',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick where you are getting off. Amica watches the distance '
                  'and sounds an alarm before you arrive, so you can rest on '
                  'the bus without missing your stop.',
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: _isLoadingLocation
                            ? 'Getting location...'
                            : 'Update current location',
                        icon: Icons.my_location_rounded,
                        onPressed: _isBusy ? null : _getCurrentLocation,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentLocation == null
                            ? 'Current location: not available yet'
                            : 'Current location: '
                                '${currentLocation.latitude.toStringAsFixed(5)}, '
                                '${currentLocation.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Where are you getting off?',
                  controller: _dropOffController,
                  prefixIcon: Icons.directions_bus_filled_outlined,
                  validator: _validateDropOff,
                ),
                if (_isResolvingDropOff || _dropOffStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isResolvingDropOff
                        ? 'Finding your stop on the map...'
                        : _dropOffStatus!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                AmicaMapView(
                  latitude: mapCenter.latitude,
                  longitude: mapCenter.longitude,
                  markerTitle: 'You are here',
                  showStartMarker: currentLocation != null,
                  destinationLatitude: dropOffLocation?.latitude,
                  destinationLongitude: dropOffLocation?.longitude,
                  destinationTitle: dropOffTitle,
                  onTap: _isStartingRide ? null : _pinDropOff,
                ),
                const SizedBox(height: 8),
                Text(
                  dropOffLocation == null
                      ? 'Tap the map to pin your stop.'
                      : 'Stop pinned at '
                          '${dropOffLocation.latitude.toStringAsFixed(5)}, '
                          '${dropOffLocation.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                _buildAlertDistancePicker(context),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.alert),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isStartingRide ? 'Starting...' : 'Start bus ride',
                  icon: Icons.notifications_active_rounded,
                  onPressed: (_isBusy || _isResolvingDropOff) ? null : _startRide,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keep the Amica tracking notification visible. The alarm '
                  'still sounds with the app closed and the screen off.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertDistancePicker(BuildContext context) {
    final distance = _distanceToDropOff;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert me this far from the stop',
            style: Theme.of(context).textTheme.titleMedium,
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
              'Checking the road distance to your stop...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else if (distance != null) ...[
            const SizedBox(height: 14),
            Text(
              _routeEstimate == null
                  // Said plainly, because it reads shorter than the ride will
                  // actually be.
                  ? 'Your stop is ${widget.calculator.formatDistance(distance)} '
                      'away in a straight line.'
                  : 'Your stop is about '
                      '${widget.calculator.formatDistance(distance)} away by road.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_alertDistanceTooLarge) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are already within '
                    '${widget.calculator.formatAlertDistance(_alertDistanceMeters)} '
                    'of this stop, so the alarm would sound straight away. '
                    'Pick a shorter alert distance.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
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
