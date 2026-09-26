import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/navigation/amica_shell.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/journey_route_service.dart';
import '../../../services/location_service.dart';
import '../../../services/transit_plan_service.dart';
import '../../plate_scan/models/scanned_vehicle.dart';
import '../../stop_alert/services/route_distance_service.dart';
import '../../stop_alert/services/stop_alert_calculator.dart';
import '../models/journey.dart';
import '../models/location_data_model.dart';
import '../widgets/journey_history_button.dart';
import '../widgets/journey_visuals.dart';
import '../widgets/transit_trip_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/journey_service.dart';
import '../services/journey_share_service.dart';

class StartJourneyScreen extends StatefulWidget {
  const StartJourneyScreen({
    super.key,
    this.locationService = const LocationService(),
    this.journeyService = const JourneyService(),
    this.routeService = const JourneyRouteService(),
    this.transitService = const TransitPlanService(),
    this.routeDistanceService = const RouteDistanceService(),
    this.vehiclePlate,
    this.boardingStatus,
    this.isTab = false,
  });

  final LocationService locationService;
  final JourneyService journeyService;
  final JourneyRouteService routeService;
  final TransitPlanService transitService;
  final RouteDistanceService routeDistanceService;
  final String? vehiclePlate;
  final String? boardingStatus;

  /// True when shown as the Journeys tab rather than pushed as a route —
  /// suppresses the back arrow, since there is nothing to go back to.
  final bool isTab;

  @override
  State<StartJourneyScreen> createState() => _StartJourneyScreenState();
}

class _StartJourneyScreenState extends State<StartJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: '20');

  Timer? _destinationSearchDebounce;
  Timer? _routeDebounce;
  JourneyRoute? _route;
  int _routeToken = 0;

  // Bus / train trip plan: stops to get on and off at, walks either side.
  TransitPlan? _plan;
  List<MapRouteLeg> _planLegs = const [];
  bool _isLoadingPlan = false;
  TransitPlanUnavailable? _planUnavailable;
  int _planToken = 0;
  String? _boardStopId;
  String? _alightStopId;

  bool get _usesTransit => _journeyType == 'bus' || _journeyType == 'train';

  /// A taxi the rider scanned from this screen (the "Scan vehicle" button).
  ScannedVehicle? _scannedVehicle;

  /// The plate this journey is for: the one it was opened with, or a taxi
  /// scanned here. A scan only counts while Taxi is still the chosen type.
  String? get _vehiclePlate =>
      widget.vehiclePlate ??
      (_journeyType == 'taxi' ? _scannedVehicle?.plate : null);

  String? get _boardingStatus =>
      widget.boardingStatus ?? _scannedVehicle?.boardingStatus;

  /// Bus / train: sound an alarm before the stop she gets off at.
  bool _stopAlertEnabled = true;
  int _stopAlertDistanceMeters = Journey.defaultAlertDistanceMeters;

  /// Alert distances that still make sense for this trip: an alarm that would
  /// already be sounding at the start of a short ride is no use.
  List<int> get _stopAlertOptions {
    final tripMeters = _route?.distanceMeters;
    final options = [
      for (final meters in StopAlertCalculator.alertDistanceOptionsMeters)
        if (tripMeters == null || meters < tripMeters * 0.8) meters,
    ];
    return options.isEmpty
        ? [StopAlertCalculator.alertDistanceOptionsMeters.first]
        : options;
  }

  int get _effectiveStopAlertDistance {
    final options = _stopAlertOptions;
    if (options.contains(_stopAlertDistanceMeters)) {
      return _stopAlertDistanceMeters;
    }
    return options.lastWhere(
      (meters) => meters <= _stopAlertDistanceMeters,
      orElse: () => options.first,
    );
  }

  Future<void> _scanVehicle() async {
    final scanned = await Navigator.pushNamed<ScannedVehicle>(
      context,
      AppRoutes.plateScan,
      arguments: const PlateScanArguments(returnVehicle: true),
    );
    if (!mounted || scanned == null) return;
    setState(() => _scannedVehicle = scanned);
  }
  int _reverseGeocodeToken = 0;
  bool _isLoadingRoute = false;
  bool _routeUnavailable = false;

  /// Set while the app itself writes the destination text (after a map pick),
  /// so that write is not mistaken for the user typing a new place.
  bool _isSettingDestinationText = false;
  String _lastDestinationText = '';
  LocationDataModel? _currentLocation;
  LocationDataModel? _destinationLocation;
  int _destinationSearchToken = 0;
  String _journeyType = 'walk';
  int _suggestedDurationMinutes = 20;
  bool _isLoadingLocation = false;
  bool _isResolvingDestination = false;
  bool _isStartingJourney = false;

  /// "Share live with my circle": text/push a watch-live link on start.
  bool _shareLive = true;
  bool _durationWasEdited = false;
  bool _isUpdatingDurationText = false;
  String? _destinationStatus;
  String? _errorMessage;

  bool get _isBusy => _isLoadingLocation || _isStartingJourney;

  @override
  void initState() {
    super.initState();
    if (widget.vehiclePlate != null) _journeyType = 'taxi';
    _destinationController.addListener(_onDestinationTextChanged);
    _durationController.addListener(_onDurationTextChanged);
    JourneyShareService.instance.loadShareByDefault().then((value) {
      if (mounted) setState(() => _shareLive = value);
    });
    if (!widget.isTab) {
      // Pushed as its own screen: it is visible now, so locate straight away.
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocate());
    }
  }

  ValueListenable<int>? _shellTab;
  bool _autoLocateAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isTab) return;
    // As the Journeys tab the screen is built at app start behind Home, so
    // wait until the tab is actually opened before asking for location —
    // otherwise the permission prompt would pop up over the Home screen.
    final tab = AmicaShellScope.maybeOf(context)?.currentTab;
    if (tab == _shellTab) return;
    _shellTab?.removeListener(_onShellTabChanged);
    _shellTab = tab?..addListener(_onShellTabChanged);
    if (tab == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocate());
    } else {
      _onShellTabChanged();
    }
  }

  void _onShellTabChanged() {
    if (_shellTab?.value == AmicaShellScope.journeysTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoLocate());
    }
  }

  /// Finds where she is without being asked: first the phone's last known
  /// fix (instant, puts the map in the right place), then a precise one.
  /// Tried once per screen; the refresh button is always there after that.
  Future<void> _autoLocate() async {
    if (!mounted ||
        _autoLocateAttempted ||
        _currentLocation != null ||
        _isLoadingLocation) {
      return;
    }
    _autoLocateAttempted = true;
    final quick = await widget.locationService.getLastKnownLocationData();
    if (mounted && quick != null && _currentLocation == null) {
      setState(() => _currentLocation = quick);
    }
    if (mounted) await _getCurrentLocation();
  }

  @override
  void dispose() {
    _shellTab?.removeListener(_onShellTabChanged);
    _destinationSearchDebounce?.cancel();
    _routeDebounce?.cancel();
    _destinationController
      ..removeListener(_onDestinationTextChanged)
      ..dispose();
    _durationController
      ..removeListener(_onDurationTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onDurationTextChanged() {
    if (!_isUpdatingDurationText) {
      _durationWasEdited = true;
    }
  }

  void _onDestinationTextChanged() {
    final destinationName = _destinationController.text.trim();
    if (_isSettingDestinationText) {
      _lastDestinationText = destinationName;
      return;
    }
    // The controller also notifies on cursor and selection moves. Only a real
    // edit should drop the pin, or tapping the field would lose it.
    if (destinationName == _lastDestinationText) {
      return;
    }
    _lastDestinationText = destinationName;
    // Typing replaces any address lookup still running for an old pin.
    _reverseGeocodeToken++;

    // A previous pin must never silently become a different destination.
    _destinationLocation = null;
    if (mounted) {
      setState(_clearRoute);
    }

    _scheduleDestinationLookup(destinationName);
  }

  /// The ✕ on the destination field: drops the text, the pin, the route and
  /// any bus/train plan in one go.
  void _clearDestination() {
    _destinationSearchDebounce?.cancel();
    _destinationSearchToken++;
    _reverseGeocodeToken++;
    _planToken++;
    _destinationController.clear();
    setState(() {
      _destinationLocation = null;
      _destinationStatus = null;
      _isResolvingDestination = false;
      _errorMessage = null;
      _clearRoute();
      _plan = null;
      _planLegs = const [];
      _isLoadingPlan = false;
      _planUnavailable = null;
      _boardStopId = null;
      _alightStopId = null;
    });
  }

  void _scheduleDestinationLookup(String destinationName) {
    _destinationSearchDebounce?.cancel();

    if (destinationName.length < 3) {
      _destinationSearchToken++;
      if (mounted) {
        setState(() {
          _destinationStatus = null;
          _isResolvingDestination = false;
        });
      }
      return;
    }

    final searchToken = ++_destinationSearchToken;
    _destinationSearchDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _findDestinationOnMap(destinationName, searchToken),
    );
  }

  Future<void> _findDestinationOnMap(
    String destinationName,
    int searchToken,
  ) async {
    if (!mounted || destinationName != _destinationController.text.trim()) {
      return;
    }

    final loc = AppLocalizations.of(context);
    setState(() {
      _isResolvingDestination = true;
      _destinationStatus = loc.startJourneyFindingOnMap;
      _errorMessage = null;
    });

    try {
      final matches = await geocoding
          .locationFromAddress(destinationName)
          .timeout(const Duration(seconds: 6));
      if (matches.isEmpty) {
        throw const FormatException('No destination found');
      }

      final match = matches.first;
      if (!mounted || searchToken != _destinationSearchToken) {
        return;
      }

      setState(() {
        _destinationLocation = LocationDataModel(
          latitude: match.latitude,
          longitude: match.longitude,
          address: destinationName,
          updatedAt: DateTime.now(),
        );
        _destinationStatus = loc.startJourneyDestinationFound;
      });
      _applySuggestedDuration();
      _scheduleRouteLookup();
    } catch (_) {
      if (mounted && searchToken == _destinationSearchToken) {
        setState(() {
          _destinationStatus = loc.startJourneyDestinationNotFound;
        });
      }
    } finally {
      if (mounted && searchToken == _destinationSearchToken) {
        setState(() => _isResolvingDestination = false);
      }
    }
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
        _applySuggestedDuration();
        _scheduleRouteLookup();
        _scheduleDestinationLookup(_destinationController.text.trim());
      }
    } on LocationServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            AppLocalizations.of(context).startJourneyCouldNotGetLocation);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _startJourney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loc = AppLocalizations.of(context);
    final startLocation = _currentLocation;
    if (startLocation == null) {
      setState(() => _errorMessage = loc.startJourneyGetLocationFirst);
      return;
    }

    final destinationLocation = _destinationLocation;
    if (destinationLocation == null) {
      setState(() => _errorMessage = loc.startJourneyChooseDestination);
      return;
    }

    setState(() {
      _isStartingJourney = true;
      _errorMessage = null;
    });

    try {
      // Bus / train with the stop alert on: the alarm counts down to the stop
      // she gets off at (from the trip plan, or the place she chose).
      StopAlertSettings? stopAlert;
      if (_usesTransit && _stopAlertEnabled) {
        final plan = _plan;
        final target = plan != null
            ? LocationDataModel(
                latitude: plan.alightStop.latitude,
                longitude: plan.alightStop.longitude,
                address: plan.alightStop.name,
                updatedAt: DateTime.now(),
              )
            : destinationLocation;
        // Road distance is looked up once, now, so the alarm can work offline
        // for the rest of the ride. No answer just means straight-line.
        final estimate = await widget.routeDistanceService.estimate(
          originLatitude: startLocation.latitude,
          originLongitude: startLocation.longitude,
          destinationLatitude: target.latitude,
          destinationLongitude: target.longitude,
        );
        stopAlert = StopAlertSettings(
          dropOff: target,
          dropOffName: plan?.alightStop.name ?? _destinationController.text.trim(),
          alertDistanceMeters: _effectiveStopAlertDistance,
          routeFactor: estimate?.routeFactor ?? 1,
          routeDistanceMeters: estimate?.roadDistanceMeters,
        );
      }

      final journeyId = await widget.journeyService.startJourney(
        startLocation: startLocation,
        destinationName: _destinationController.text.trim(),
        destinationLocation: destinationLocation.copyWith(
          address: _destinationController.text.trim(),
          updatedAt: DateTime.now(),
        ),
        estimatedDurationMinutes:
            int.tryParse(_durationController.text.trim()) ??
                _suggestedDurationMinutes,
        journeyType: _journeyType,
        vehiclePlate: _vehiclePlate,
        route: _route?.mode == routeModeForJourneyType(_journeyType)
            ? _route
            : null,
        transitPlan: _usesTransit ? _plan : null,
        stopAlert: stopAlert,
      );

      if (_shareLive) {
        // Runs on after this screen closes; the journey screen shows how it
        // went (see JourneyShareService.outcome).
        unawaited(JourneyShareService.instance.shareWithCircle(
          journeyId: journeyId,
          destinationName: _destinationController.text.trim(),
          loc: loc,
        ));
      }

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.journeyTimer,
        arguments: journeyId,
      );
    } on JourneyServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage =
            AppLocalizations.of(context).startJourneyCouldNotStart);
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingJourney = false);
      }
    }
  }

  void _pinDestination(double latitude, double longitude) {
    _destinationSearchDebounce?.cancel();
    _destinationSearchToken++;
    setState(() {
      _destinationLocation = LocationDataModel(
        latitude: latitude,
        longitude: longitude,
        address: _destinationController.text.trim(),
        updatedAt: DateTime.now(),
      );
      _destinationStatus =
          AppLocalizations.of(context).startJourneyFindingAddress;
      _isResolvingDestination = false;
      _errorMessage = null;
    });
    _applySuggestedDuration();
    _scheduleRouteLookup();
    unawaited(_fillAddressForPin(latitude, longitude));
  }

  /// Looks up a readable address for a pin dropped on the map and writes it
  /// into the destination field.
  Future<void> _fillAddressForPin(double latitude, double longitude) async {
    final token = ++_reverseGeocodeToken;
    String? address;
    try {
      final placemarks = await geocoding
          .placemarkFromCoordinates(latitude, longitude)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isNotEmpty) {
        address = _formatPlacemark(placemarks.first);
      }
    } catch (_) {
      address = null;
    }

    if (!mounted || token != _reverseGeocodeToken) {
      return;
    }
    final destination = _destinationLocation;
    if (destination == null ||
        destination.latitude != latitude ||
        destination.longitude != longitude) {
      return;
    }

    final loc = AppLocalizations.of(context);
    if (address == null || address.isEmpty) {
      setState(() => _destinationStatus = loc.startJourneyAddressNotFound);
      return;
    }

    _isSettingDestinationText = true;
    _destinationController.value = TextEditingValue(
      text: address,
      selection: TextSelection.collapsed(offset: address.length),
    );
    _isSettingDestinationText = false;
    setState(() {
      _destinationLocation = destination.copyWith(address: address);
      _destinationStatus = loc.startJourneyDestinationPinSelected;
    });
  }

  /// "No. 12, Galle Road, Wellawatte, Colombo" from the most useful parts of
  /// a placemark, without repeats (Android often gives the same text twice).
  String _formatPlacemark(geocoding.Placemark placemark) {
    final parts = <String>[];
    void add(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || parts.contains(text)) {
        return;
      }
      // Skip bare plus-codes such as "7QJ2+XX", which mean nothing to people.
      if (RegExp(r'^[23456789CFGHJMPQRVWX]{4,}\+[23456789CFGHJMPQRVWX]*$')
          .hasMatch(text)) {
        return;
      }
      parts.add(text);
    }

    add(placemark.name);
    add(placemark.street);
    add(placemark.subLocality);
    add(placemark.locality);
    if (parts.length < 2) {
      add(placemark.subAdministrativeArea);
    }
    return parts.join(', ');
  }

  void _clearRoute() {
    _routeDebounce?.cancel();
    _routeToken++;
    _route = null;
    _isLoadingRoute = false;
    _routeUnavailable = false;
  }

  /// Fetches the suggested route once both ends are known, debounced so that
  /// dragging the pin around does not fire a request per move.
  void _scheduleRouteLookup() {
    _routeDebounce?.cancel();
    final start = _currentLocation;
    final destination = _destinationLocation;
    if (start == null || destination == null) {
      return;
    }

    final token = ++_routeToken;
    final mode = routeModeForJourneyType(_journeyType);
    setState(() {
      _isLoadingRoute = true;
      _routeUnavailable = false;
    });
    _routeDebounce = Timer(const Duration(milliseconds: 500), () async {
      final route = await widget.routeService.fetchRoute(
        originLatitude: start.latitude,
        originLongitude: start.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        mode: mode,
      );
      if (!mounted || token != _routeToken) {
        return;
      }
      setState(() {
        _route = route;
        _isLoadingRoute = false;
        _routeUnavailable = route == null;
      });
      _applySuggestedDuration();
    });
    _schedulePlanLookup();
  }

  /// For bus and train journeys: which stop to get on at, which to get off
  /// at, and the walks to and from them.
  void _schedulePlanLookup() {
    final start = _currentLocation;
    final destination = _destinationLocation;
    final token = ++_planToken;
    if (!_usesTransit || start == null || destination == null) {
      if (_plan != null || _isLoadingPlan) {
        setState(() {
          _plan = null;
          _planLegs = const [];
          _isLoadingPlan = false;
          _planUnavailable = null;
        });
      }
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
        mode: _journeyType,
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
      _applySuggestedDuration();
    }());
  }

  /// The rider picked a different stop — from the chips or on the map.
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
    _schedulePlanLookup();
  }

  void _onJourneyTypeChanged(String? value) {
    setState(() => _journeyType = value ?? 'walk');
    _boardStopId = null;
    _alightStopId = null;
    _schedulePlanLookup();
    _applySuggestedDuration();
    if (_route?.mode != routeModeForJourneyType(_journeyType)) {
      _scheduleRouteLookup();
    }
  }

  void _applySuggestedDuration({bool force = false}) {
    final suggestedDuration = _estimateDurationMinutes();

    if (mounted) {
      setState(() => _suggestedDurationMinutes = suggestedDuration);
    } else {
      _suggestedDurationMinutes = suggestedDuration;
    }

    if (force || !_durationWasEdited) {
      _isUpdatingDurationText = true;
      _durationController.text = suggestedDuration.toString();
      _durationController.selection = TextSelection.collapsed(
        offset: _durationController.text.length,
      );
      _isUpdatingDurationText = false;
    }
  }

  int _estimateDurationMinutes() {
    final fallback = _fallbackDurationMinutes();
    final start = _currentLocation;
    final destination = _destinationLocation;
    if (start == null || destination == null) {
      return fallback;
    }

    final buffer = _journeyType == 'walk' ? 1.15 : 1.35;
    final plan = _plan;
    if (_usesTransit && plan != null) {
      // Walks + ride, the same buffer, and ten minutes for waiting at the
      // stop — buses here do not run to a timetable you can count on.
      final minutes = (plan.durationSeconds / 60 * buffer).ceil() + 10;
      return math.max(10, minutes);
    }
    final route = _route;
    if (route != null && route.mode == routeModeForJourneyType(_journeyType)) {
      // Directions' own prediction along the real route, plus the same
      // safety buffer, so the timer does not run out on an ordinary walk.
      final minutes = (route.durationSeconds / 60 * buffer).ceil();
      return math.max(5, minutes);
    }

    final distanceKm = _distanceInKm(
      start.latitude,
      start.longitude,
      destination.latitude,
      destination.longitude,
    );
    if (distanceKm < 0.1) {
      return 5;
    }

    final speedKmh = switch (_journeyType) {
      'walk' => 5.0,
      'taxi' => 30.0,
      'bus' => 22.0,
      'train' => 45.0,
      _ => 20.0,
    };
    final minutes = (distanceKm / speedKmh * 60 * buffer).ceil();
    return math.max(5, minutes);
  }

  int _fallbackDurationMinutes() {
    return switch (_journeyType) {
      'walk' => 20,
      'taxi' => 15,
      'bus' => 30,
      'train' => 45,
      _ => 25,
    };
  }

  double _distanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    final latDistance = _degreesToRadians(endLatitude - startLatitude);
    final lonDistance = _degreesToRadians(endLongitude - startLongitude);
    final startLat = _degreesToRadians(startLatitude);
    final endLat = _degreesToRadians(endLatitude);

    final a = math.sin(latDistance / 2) * math.sin(latDistance / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(lonDistance / 2) *
            math.sin(lonDistance / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  String? _required(BuildContext context, String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).fieldRequired(fieldName);
    }
    return null;
  }

  String? _validateDuration(BuildContext context, String? value) {
    final duration = int.tryParse(value?.trim() ?? '');
    if (duration == null || duration <= 0) {
      return AppLocalizations.of(context).startJourneyDurationInvalid;
    }
    return null;
  }

  static const double _sheetInitialSize = 0.46;
  static const double _sheetMinSize = 0.18;
  static const double _sheetMaxSize = 0.92;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLocation = _currentLocation;
    final destinationLocation = _destinationLocation;
    final mapCenter = currentLocation ??
        destinationLocation ??
        LocationDataModel(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'Colombo',
          updatedAt: DateTime.now(),
        );
    final destinationTitle = _destinationController.text.trim().isEmpty
        ? loc.startJourneyDestinationLabel
        : _destinationController.text.trim();
    final c = Theme.of(context).amica;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        title: Text(_vehiclePlate == null
            ? loc.startJourneyWalkWithMeTitle
            : loc.startJourneyRideWithMeTitle),
        actions: const [JourneyHistoryButton()],
      ),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: AmicaMapView(
                      latitude: mapCenter.latitude,
                      longitude: mapCenter.longitude,
                      height: null,
                      borderRadius: 0,
                      markerTitle: loc.startJourneyMapStartMarker,
                      showStartMarker: currentLocation != null,
                      // The blue dot needs location permission, which is only
                      // known to be granted once a location has been read.
                      showMyLocation: currentLocation != null,
                      destinationLatitude: destinationLocation?.latitude,
                      destinationLongitude: destinationLocation?.longitude,
                      destinationTitle: destinationTitle,
                      routePoints: _usesTransit && _plan != null
                          ? const []
                          : (_route?.points ??
                              // No route from the backend (not deployed,
                              // offline, no key)? Show a straight guide line
                              // so the map never looks empty.
                              ((_usesTransit && _planLegs.isNotEmpty) ||
                                      _isLoadingRoute ||
                                      _isLoadingPlan ||
                                      currentLocation == null ||
                                      destinationLocation == null
                                  ? const <LatLng>[]
                                  : [
                                      LatLng(currentLocation.latitude,
                                          currentLocation.longitude),
                                      LatLng(destinationLocation.latitude,
                                          destinationLocation.longitude),
                                    ])),
                      routeLegs: _usesTransit ? _planLegs : const [],
                      transitStops: _usesTransit && _plan != null
                          ? mapStopsFor(_plan!, withCandidates: true)
                          : const [],
                      onTransitStopTap: _isStartingJourney
                          ? null
                          : (stop) => _chooseStop(stop.id),
                      mapPadding: EdgeInsets.only(
                        top: topInset,
                        bottom: constraints.maxHeight * _sheetInitialSize,
                      ),
                      onTap: _isStartingJourney ? null : _pinDestination,
                      onDestinationDragged:
                          _isStartingJourney ? null : _pinDestination,
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
                    builder: (context, scrollController) =>
                        _buildSheet(context, scrollController),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTaxiScanCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final textTheme = Theme.of(context).textTheme;
    final scanned = _scannedVehicle != null;
    return AmicaCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: c.accentInk),
              const SizedBox(width: 10),
              Expanded(
                child: Text(loc.startJourneyScanVehicleTitle,
                    style: textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(loc.startJourneyScanVehicleSubtitle, style: textTheme.bodySmall),
          const SizedBox(height: 12),
          PrimaryButton(
            tone: scanned ? AmicaButtonTone.quiet : AmicaButtonTone.primary,
            label: scanned
                ? loc.startJourneyScanAgainButton
                : loc.startJourneyScanVehicleButton,
            icon: Icons.document_scanner_outlined,
            onPressed: _isBusy ? null : _scanVehicle,
          ),
        ],
      ),
    );
  }

  Widget _buildStopAlertCard(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final textTheme = Theme.of(context).textTheme;
    const calculator = StopAlertCalculator();
    return AmicaCard(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _stopAlertEnabled,
            onChanged: _isBusy
                ? null
                : (value) => setState(() => _stopAlertEnabled = value),
            secondary:
                Icon(Icons.notifications_active_rounded, color: c.accentInk),
            title: Text(loc.startJourneyStopAlertTitle,
                style: textTheme.titleSmall),
            subtitle: Text(loc.startJourneyStopAlertSubtitle,
                style: textTheme.bodySmall),
          ),
          if (_stopAlertEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(loc.startJourneyStopAlertDistanceLabel,
                  style: textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final meters in _stopAlertOptions)
                  ChoiceChip(
                    selected: meters == _effectiveStopAlertDistance,
                    label: Text(calculator.formatAlertDistance(meters)),
                    onSelected: _isBusy
                        ? null
                        : (_) =>
                            setState(() => _stopAlertDistanceMeters = meters),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSheet(BuildContext context, ScrollController scrollController) {
    final loc = AppLocalizations.of(context);
    final c = Theme.of(context).amica;
    final textTheme = Theme.of(context).textTheme;
    final currentLocation = _currentLocation;
    final destinationLocation = _destinationLocation;

    final journeyTypes = <(String, String)>[
      ('walk', loc.startJourneyTypeWalk),
      ('taxi', loc.startJourneyTypeTaxi),
      ('bus', loc.startJourneyTypeBus),
      ('train', loc.startJourneyTypeTrain),
      ('other', loc.startJourneyTypeOther),
    ];

    return JourneyGlassSheet(
      scrollController: scrollController,
      children: [
        if (_vehiclePlate != null) ...[
          Row(
            children: [
              GradientIconBadge(icon: journeyTypeIcon(_journeyType)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.startJourneyVehicleLabel(_vehiclePlate!),
                        style: textTheme.titleLarge),
                    if (_boardingStatus != null)
                      Text(_boardingStatus!, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        // From — where the journey starts.
        if (currentLocation == null)
          PrimaryButton(
            label: _isLoadingLocation
                ? loc.startJourneyGettingLocation
                : loc.startJourneyGetCurrentLocation,
            icon: Icons.my_location_rounded,
            onPressed: _isBusy ? null : _getCurrentLocation,
          )
        else
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
                      Text(loc.startJourneyYourLocation,
                          style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${currentLocation.latitude.toStringAsFixed(5)}, '
                        '${currentLocation.longitude.toStringAsFixed(5)}',
                        style: textTheme.bodySmall?.copyWith(color: c.plum45),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: loc.startJourneyGetCurrentLocation,
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
        // To — where it ends.
        CustomTextField(
          label: loc.startJourneyDestinationNameLabel,
          controller: _destinationController,
          prefixIcon: Icons.favorite_border_rounded,
          enabled: !_isStartingJourney,
          onClear: _clearDestination,
          validator: (value) =>
              _required(context, value, loc.startJourneyDestinationLabel),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              destinationLocation == null
                  ? Icons.touch_app_outlined
                  : Icons.place_rounded,
              size: 15,
              color: c.plum45,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isResolvingDestination
                    ? loc.startJourneyFindingOnMap
                    : _destinationStatus ??
                        (destinationLocation == null
                            ? loc.startJourneyTapMapToPin
                            : loc.startJourneyDestinationPinValue(
                                destinationLocation.latitude
                                    .toStringAsFixed(5),
                                destinationLocation.longitude
                                    .toStringAsFixed(5),
                              )),
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (_usesTransit) ...[
          const SizedBox(height: 12),
          TransitTripCard(
            mode: _journeyType,
            plan: _plan,
            isLoading: _isLoadingPlan,
            unavailable: _planUnavailable,
            onChooseBoard:
                _isStartingJourney ? null : (stop) => _chooseStop(stop.id),
            onChooseAlight:
                _isStartingJourney ? null : (stop) => _chooseStop(stop.id),
          ),
        ] else if (_isLoadingRoute || _route != null || _routeUnavailable) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: InfoPill(
              icon: journeyTypeIcon(_journeyType),
              label: _isLoadingRoute
                  ? loc.startJourneyRouteLoading
                  : _route != null
                      ? loc.startJourneyRouteSummary(
                          formatDistance(_route!.distanceMeters),
                          (_route!.durationSeconds / 60).ceil(),
                        )
                      : loc.startJourneyRouteUnavailable,
            ),
          ),
        ],
        const SizedBox(height: 18),
        // How — journey type as tappable icon chips.
        Text(
          loc.startJourneyTypeLabel,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: c.plum70,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (type, label) in journeyTypes) ...[
                JourneyTypeChip(
                  type: type,
                  label: label,
                  selected: _journeyType == type,
                  onTap: _isBusy ? null : () => _onJourneyTypeChanged(type),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        // Taxi: scan the plate before riding, so the journey knows the vehicle.
        if (_journeyType == 'taxi' && widget.vehiclePlate == null) ...[
          const SizedBox(height: 14),
          _buildTaxiScanCard(context),
        ],
        // Bus / train: the stop alarm, right here in the journey.
        if (_usesTransit) ...[
          const SizedBox(height: 14),
          _buildStopAlertCard(context),
        ],
        const SizedBox(height: 16),
        // For how long.
        CustomTextField(
          label: loc.startJourneyDurationLabel,
          controller: _durationController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.timer_outlined,
          validator: (value) => _validateDuration(context, value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 15, color: c.accentInk),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loc.startJourneySuggestedDuration(_suggestedDurationMinutes),
                style: textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: c.terracottaDeep),
          ),
        ],
        const SizedBox(height: 16),
        // Watch-live link for her circle.
        AmicaCard(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _shareLive,
            onChanged: _isBusy
                ? null
                : (value) {
                    setState(() => _shareLive = value);
                    unawaited(
                      JourneyShareService.instance.saveShareByDefault(value),
                    );
                  },
            secondary: Icon(Icons.podcasts_rounded, color: c.accentInk),
            title: Text(
              loc.liveShareToggleTitle,
              style: textTheme.titleSmall,
            ),
            subtitle: Text(
              loc.liveShareToggleSubtitle,
              style: textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: _isStartingJourney
              ? loc.startJourneyStarting
              : _vehiclePlate == null
                  ? loc.startJourneyStartButton
                  : loc.startJourneyStartVehicleButton,
          icon: Icons.play_arrow_rounded,
          onPressed:
              (_isBusy || _isResolvingDestination) ? null : _startJourney,
        ),
      ],
    );
  }
}
