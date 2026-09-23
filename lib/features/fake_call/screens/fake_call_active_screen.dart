import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../services/emergency_action_service.dart';
import '../../../services/location_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../services/fake_call_service.dart';
import '../../../l10n/generated/app_localizations.dart';
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
    this.emergencyActionService = const EmergencyActionService(),
    this.emergencyContactService = const EmergencyContactService(),
    VoiceSosService? voiceSosService,
  }) : voiceSosService = voiceSosService ?? VoiceSosService();

  final FakeCallActiveArguments? arguments;
  final UserProfileService userProfileService;
  final LocationService locationService;
  final SosService sosService;
  final FakeCallService fakeCallService;
  final EmergencyActionService emergencyActionService;
  final EmergencyContactService emergencyContactService;
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
  bool _isTriggeringSos = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.emergencyActionService.setCallProximityEnabled(enabled: true),
    );
    _startCallTimer();
    _startVoiceSos();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    widget.voiceSosService.stopListening();
    unawaited(
      widget.emergencyActionService.setCallProximityEnabled(enabled: false),
    );
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
    final phrases = await widget.userProfileService.getSecretPhrases();
    final phrase = phrases.first;
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
    });

    if (!voiceSosEnabled || !secretPhraseEnabled) {
      return;
    }

    try {
      await widget.emergencyActionService.prepareEmergencyPermissions();
    } catch (_) {
      // Voice SOS can still create a Firestore alert. Direct SMS will need
      // Android SMS permission before it can be sent.
    }

    await widget.voiceSosService.startListening(
      expectedPhrase: phrase,
      expectedPhrases: phrases,
      onMatchedPhrase: (matched) => _expectedPhrase = matched,
      onTextDetected: (detectedText) {
        _lastDetectedText = detectedText;
      },
      onSecretPhraseDetected: () => _triggerVoiceSos(_lastDetectedText),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
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
        emergencyMessage: _voiceSosEmergencyMessage,
      );
      // The SOS screen texts the whole circle (not just the first contact)
      // and shows who was actually reached.

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
    } on EmergencyContactServiceException catch (error) {
      _showError(error.message);
    } on EmergencyActionException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      _showError(
        AppLocalizations.of(context).fakeCallActiveCouldNotCompleteVoiceSos,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isTriggeringSos = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _endCall() async {
    await widget.voiceSosService.stopListening();
    await widget.emergencyActionService.setCallProximityEnabled(enabled: false);
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
    final loc = AppLocalizations.of(context);
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
            Text(
              loc.fakeCallMobile,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
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
            Text(
              loc.fakeCallActiveConnected,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 56),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallControlButton(icon: Icons.mic_off, label: loc.fakeCallActiveMute),
                _CallControlButton(icon: Icons.dialpad, label: loc.fakeCallActiveKeypad),
                _CallControlButton(icon: Icons.volume_up, label: loc.fakeCallActiveSpeaker),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallControlButton(icon: Icons.add, label: loc.fakeCallActiveAddCall),
                _CallControlButton(icon: Icons.pause, label: loc.fakeCallActiveHold),
                _CallControlButton(icon: Icons.bluetooth, label: loc.fakeCallActiveBluetooth),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: FloatingActionButton(
                heroTag: 'endCall',
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
