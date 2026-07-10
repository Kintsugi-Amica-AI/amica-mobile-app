import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_map_view.dart';
import '../../../core/widgets/custom_text_field.dart';
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

  LocationDataModel? _currentLocation;
  String _journeyType = 'walk';
  bool _isLoadingLocation = false;
  bool _isStartingJourney = false;
  String? _errorMessage;

  bool get _isBusy => _isLoadingLocation || _isStartingJourney;

  @override
  void dispose() {
    _destinationController.dispose();
    _durationController.dispose();
    super.dispose();
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

    final location = _currentLocation;
    if (location == null) {
      setState(() => _errorMessage = 'Get your current location first.');
      return;
    }

    setState(() {
      _isStartingJourney = true;
      _errorMessage = null;
    });

    try {
      final journeyId = await widget.journeyService.startJourney(
        startLocation: location,
        destinationName: _destinationController.text.trim(),
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
    final location = _currentLocation;

    return Scaffold(
      appBar: AppBar(title: const Text('Start Journey')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            PrimaryButton(
              label: _isLoadingLocation
                  ? 'Getting location...'
                  : 'Get current location',
              icon: Icons.my_location,
              onPressed: _isBusy ? null : _getCurrentLocation,
            ),
            if (location != null) ...[
              const SizedBox(height: 16),
              AmicaMapView(
                latitude: location.latitude,
                longitude: location.longitude,
                markerTitle: 'Journey start',
              ),
              const SizedBox(height: 8),
              Text(
                'Current location: ${location.latitude.toStringAsFixed(5)}, '
                '${location.longitude.toStringAsFixed(5)}',
              ),
            ],
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Destination name or address',
              controller: _destinationController,
              validator: (value) => _required(value, 'Destination'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Estimated duration in minutes',
              controller: _durationController,
              keyboardType: TextInputType.number,
              validator: _validateDuration,
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
              onChanged: _isBusy
                  ? null
                  : (value) => setState(() => _journeyType = value ?? 'walk'),
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
              icon: Icons.play_arrow,
              onPressed: _isBusy ? null : _startJourney,
            ),
          ],
        ),
      ),
    );
  }
}
