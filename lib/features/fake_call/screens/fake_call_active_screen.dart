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
  String _voiceSosEmergencyMessage =
      UserProfileService.defaultVoiceSosEmergencyMessage;
  String _lastDetectedText = '';
  String? _statusMessage;
  bool _isListening = false;
  bool _isTriggeringSos = false;
  bool _voiceSosEnabled = true;
  bool _secretPhraseEnabled = true;

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
    final settings = await widget.userProfileService.getSafetySettings();
    if (!mounted) {
      return;
    }

    final voiceSosEnabled = settings['voiceSosEnabled'] == true;
    final secretPhraseEnabled = settings['secretPhraseEnabled'] == true;
    final message = settings['voiceSosEmergencyMessage'] as String? ??
        UserProfileService.defaultVoiceSosEmergencyMessage;

    setState(() {
      _expectedPhrase = phrase;
      _voiceSosEmergencyMessage = message;
      _voiceSosEnabled = voiceSosEnabled;
      _secretPhraseEnabled = secretPhraseEnabled;
      _statusMessage = voiceSosEnabled && secretPhraseEnabled
          ? 'Voice SOS listening...'
          : 'Voice SOS is disabled in settings.';
      _isListening = voiceSosEnabled && secretPhraseEnabled;
    });

    if (!voiceSosEnabled || !secretPhraseEnabled) {
      return;
    }

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
        emergencyMessage: _voiceSosEmergencyMessage,
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
          message: _voiceSosEmergencyMessage,
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
      backgroundColor: const Color(0xFF202124),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Fake Call',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF5F6368),
              child: Text(
                callerName.isEmpty ? 'A' : callerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              callerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              callerNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              widget.fakeCallService.formatCallDuration(_callDuration),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Call connected',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF303134),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statusMessage ?? 'Voice SOS listening...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secret phrase: "$_expectedPhrase"',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SOS message: $_voiceSosEmergencyMessage',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lastDetectedText.isEmpty
                          ? 'Last detected speech: none yet'
                          : 'Last detected speech: $_lastDetectedText',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallControlButton(icon: Icons.mic_off, label: 'Mute'),
                _CallControlButton(icon: Icons.dialpad, label: 'Keypad'),
                _CallControlButton(icon: Icons.volume_up, label: 'Speaker'),
              ],
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isTriggeringSos
                  ? 'Creating SOS...'
                  : 'Trigger Voice SOS Test',
              icon: Icons.sos,
              onPressed:
                  _isTriggeringSos || !_voiceSosEnabled || !_secretPhraseEnabled
                      ? null
                      : () => _triggerVoiceSos('amica help me'),
            ),
            const SizedBox(height: 12),
            Center(
              child: FloatingActionButton(
                heroTag: 'endFakeCall',
                backgroundColor: Colors.red,
                onPressed: _endCall,
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF3C4043),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
