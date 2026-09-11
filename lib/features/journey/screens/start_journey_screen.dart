import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/location_service.dart';
import '../models/location_data_model.dart';
import '../services/journey_service.dart';

class StartJourneyScreen extends StatefulWidget {
  const StartJourneyScreen({
    super.key,
    this.locationService = const LocationService(),
    this.journeyService = const JourneyService(),
  });

  final LocationService locationService;
  final JourneyService journeyService;

  @override
  State<StartJourneyScreen> createState() => _StartJourneyScreenState();
}

class _StartJourneyScreenState extends State<StartJourneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController(text: '20');

  Timer? _destinationSearchDebounce;
  LocationDataModel? _currentLocation;
  LocationDataModel? _destinationLocation;
  int _destinationSearchToken = 0;
  String _journeyType = 'walk';
  int _suggestedDurationMinutes = 20;
  bool _isLoadingLocation = false;
  bool _isResolvingDestination = false;
  bool _isStartingJourney = false;
  bool _durationWasEdited = false;
  bool _isUpdatingDurationText = false;
  String? _destinationStatus;
  String? _errorMessage;

  bool get _isBusy => _isLoadingLocation || _isStartingJourney;

  @override
  void initState() {
    super.initState();
    _destinationController.addListener(_onDestinationTextChanged);
    _durationController.addListener(_onDurationTextChanged);
  }

  @override
  void dispose() {
    _destinationSearchDebounce?.cancel();
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

    if (_destinationLocation != null) {
      _destinationLocation = _destinationLocation!.copyWith(
        address: destinationName,
        updatedAt: DateTime.now(),
      );
    }

    _scheduleDestinationLookup(destinationName);
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

    setState(() {
      _isResolvingDestination = true;
      _destinationStatus = 'Finding destination on map...';
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
        _destinationStatus = 'Destination found on map.';
      });
      _applySuggestedDuration();
    } catch (_) {
      if (mounted && searchToken == _destinationSearchToken) {
        setState(() {
          _destinationStatus = 'Destination not found. Pin it on the map.';
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
        _scheduleDestinationLookup(_destinationController.text.trim());
      }
    } on LocationServiceException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not get current location.');
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

    final startLocation = _currentLocation;
    if (startLocation == null) {
      setState(() => _errorMessage = 'Get your current location first.');
      return;
    }

    final destinationLocation = _destinationLocation;
    if (destinationLocation == null) {
      setState(() => _errorMessage = 'Choose the destination on the map.');
      return;
    }

    setState(() {
      _isStartingJourney = true;
      _errorMessage = null;
    });

    try {
      final journeyId = await widget.journeyService.startJourney(
        startLocation: startLocation,
        destinationName: _destinationController.text.trim(),
        destinationLocation: destinationLocation.copyWith(
          address: _destinationController.text.trim(),
          updatedAt: DateTime.now(),
        ),
        estimatedDurationMinutes: int.parse(_durationController.text.trim()),
        journeyType: _journeyType,
      );

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
        setState(() => _errorMessage = 'Could not start journey.');
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
      _destinationStatus = 'Destination pin selected.';
      _errorMessage = null;
    });
    _applySuggestedDuration();
  }

  void _onJourneyTypeChanged(String? value) {
    setState(() => _journeyType = value ?? 'walk');
    _applySuggestedDuration();
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
    final buffer = _journeyType == 'walk' ? 1.15 : 1.35;
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

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final duration = int.tryParse(value?.trim() ?? '');
    if (duration == null || duration <= 0) {
      return 'Enter a positive duration';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
        ? 'Destination'
        : _destinationController.text.trim();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Start Journey')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryButton(
                        label: _isLoadingLocation
                            ? 'Getting location...'
                            : 'Get current location',
                        icon: Icons.my_location_rounded,
                        onPressed: _isBusy ? null : _getCurrentLocation,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentLocation == null
                            ? 'Current location: not selected yet'
                            : 'Current location: ${currentLocation.latitude.toStringAsFixed(5)}, '
                                '${currentLocation.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Destination name or address',
                  controller: _destinationController,
                  prefixIcon: Icons.place_outlined,
                  validator: (value) => _required(value, 'Destination'),
                ),
                if (_isResolvingDestination || _destinationStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isResolvingDestination
                        ? 'Finding destination on map...'
                        : _destinationStatus!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                AmicaMapView(
                  latitude: mapCenter.latitude,
                  longitude: mapCenter.longitude,
                  markerTitle: 'Journey start',
                  showStartMarker: currentLocation != null,
                  destinationLatitude: destinationLocation?.latitude,
                  destinationLongitude: destinationLocation?.longitude,
                  destinationTitle: destinationTitle,
                  onTap: _isStartingJourney ? null : _pinDestination,
                ),
                const SizedBox(height: 8),
                Text(
                  destinationLocation == null
                      ? 'Tap map to pin destination.'
                      : 'Destination pin: ${destinationLocation.latitude.toStringAsFixed(5)}, '
                          '${destinationLocation.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _journeyType,
                  decoration: const InputDecoration(labelText: 'Journey type'),
                  items: const [
                    DropdownMenuItem(value: 'walk', child: Text('Walk')),
                    DropdownMenuItem(value: 'taxi', child: Text('Taxi')),
                    DropdownMenuItem(value: 'bus', child: Text('Bus')),
                    DropdownMenuItem(value: 'train', child: Text('Train')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: _isBusy ? null : _onJourneyTypeChanged,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Estimated duration in minutes',
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.hourglass_bottom_rounded,
                  validator: _validateDuration,
                ),
                const SizedBox(height: 8),
                Text(
                  'Suggested duration: $_suggestedDurationMinutes minutes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isStartingJourney ? 'Starting...' : 'Start Journey',
                  icon: Icons.play_arrow_rounded,
                  onPressed: (_isBusy || _isResolvingDestination)
                      ? null
                      : _startJourney,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
