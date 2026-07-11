import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/location_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../services/fake_call_service.dart';
import '../services/voice_sos_service.dart';

class FakeCallActiveArguments {
  const FakeCallActiveArguments({
    required this.callerName,
    required this.callerNumber,
  });

  final String callerName;
  final String callerNumber;
}

class FakeCallActiveScreen extends StatefulWidget {
  FakeCallActiveScreen({
    super.key,
    this.arguments,
    this.userProfileService = const UserProfileService(),
    this.locationService = const LocationService(),
    this.sosService = const SosService(),
    this.fakeCallService = const FakeCallService(),
    VoiceSosService? voiceSosService,
  }) : voiceSosService = voiceSosService ?? VoiceSosService();

  final FakeCallActiveArguments? arguments;
  final UserProfileService userProfileService;
  final LocationService locationService;
  final SosService sosService;
  final FakeCallService fakeCallService;
  final VoiceSosService voiceSosService;

  @override
  State<FakeCallActiveScreen> createState() => _FakeCallActiveScreenState();
}

class _FakeCallActiveScreenState extends State<FakeCallActiveScreen> {
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  String _expectedPhrase = UserProfileService.defaultSecretPhrase;
  String _lastDetectedText = '';
  String? _statusMessage;
  bool _isListening = false;
  bool _isTriggeringSos = false;

  @override
  void initState() {
    super.initState();
    _startCallTimer();
    _startVoiceSos();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    widget.voiceSosService.stopListening();
    super.dispose();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDuration += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _startVoiceSos() async {
    final phrase = await widget.userProfileService.getSecretPhrase();
    if (!mounted) {
      return;
    }

    setState(() {
      _expectedPhrase = phrase;
      _statusMessage = 'Voice SOS listening...';
      _isListening = true;
    });

    await widget.voiceSosService.startListening(
      expectedPhrase: phrase,
      onTextDetected: (detectedText) {
        if (mounted) {
          setState(() => _lastDetectedText = detectedText);
        }
      },
      onSecretPhraseDetected: () => _triggerVoiceSos(_lastDetectedText),
      onError: (error) {
        if (mounted) {
          setState(() {
            _statusMessage = error;
            _isListening = false;
          });
        }
      },
    );
  }

  Future<void> _triggerVoiceSos([String? detectedPhrase]) async {
    if (_isTriggeringSos) {
      return;
    }

    setState(() {
      _isTriggeringSos = true;
      _statusMessage = 'Creating silent Voice SOS alert...';
    });

    try {
      await widget.voiceSosService.stopListening();
      final location = await widget.locationService.getCurrentLocationData();
      final phrase = detectedPhrase?.trim().isNotEmpty == true
          ? detectedPhrase!.trim()
          : _expectedPhrase;
      final alertId = await widget.sosService.createVoiceSosAlert(
        location: location,
        detectedPhrase: phrase,
        expectedPhrase: _expectedPhrase,
        confidenceScore: 0.85,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.sosActive,
        arguments: SosActiveArguments(
          alertId: alertId,
          triggerType: 'voice',
          location: location,
          message: 'Voice SOS triggered using secret phrase.',
        ),
      );
    } on LocationServiceException catch (error) {
      _showError(error.message);
    } on SosServiceException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Could not create Voice SOS alert. Use manual SOS if needed.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isTriggeringSos = false;
      _statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _endCall() async {
    await widget.voiceSosService.stopListening();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.arguments?.callerName ??
        widget.fakeCallService.getDefaultCallerName();
    final callerNumber = widget.arguments?.callerNumber ??
        widget.fakeCallService.getDefaultCallerNumber();

    return Scaffold(
      appBar: AppBar(title: const Text('Fake Call Active')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.phone_in_talk, size: 72),
          const SizedBox(height: 16),
          Text(
            callerName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            callerNumber,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            widget.fakeCallService.formatCallDuration(_callDuration),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Call connected',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_isListening ? Icons.mic : Icons.mic_off),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_statusMessage ?? 'Voice SOS listening...'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Secret phrase: "$_expectedPhrase"'),
                  const SizedBox(height: 12),
                  Text(
                    _lastDetectedText.isEmpty
                        ? 'Last detected speech: none yet'
                        : 'Last detected speech: $_lastDetectedText',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label:
                _isTriggeringSos ? 'Creating SOS...' : 'Trigger Voice SOS Test',
            icon: Icons.sos,
            onPressed: _isTriggeringSos
                ? null
                : () => _triggerVoiceSos('amica help me'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _endCall,
            icon: const Icon(Icons.call_end),
            label: const Text('End Call'),
          ),
        ],
      ),
    );
  }
}
