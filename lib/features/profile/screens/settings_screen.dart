import 'package:flutter/material.dart';

import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/services/user_profile_service.dart';
import '../../fake_call/services/fake_call_shortcut_service.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    super.key,
    this.userProfileService = const UserProfileService(),
    FakeCallShortcutService? fakeCallShortcutService,
  }) : fakeCallShortcutService =
            fakeCallShortcutService ?? FakeCallShortcutService();

  final UserProfileService userProfileService;
  final FakeCallShortcutService fakeCallShortcutService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secretPhraseController = TextEditingController();
  final _callerNameController = TextEditingController();
  final _callerNumberController = TextEditingController();
  final _voiceSosMessageController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _voiceSosEnabled = true;
  bool _secretPhraseEnabled = true;
  bool _fakeCallVolumeShortcutEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _secretPhraseController.dispose();
    _callerNameController.dispose();
    _callerNumberController.dispose();
    _voiceSosMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final secretPhrase = await widget.userProfileService.getSecretPhrase();
      final settings = await widget.userProfileService.getSafetySettings();

      if (!mounted) {
        return;
      }

      setState(() {
        _secretPhraseController.text = secretPhrase;
        _callerNameController.text =
            settings['fakeCallContactName'] as String? ??
                UserProfileService.defaultFakeCallContactName;
        _callerNumberController.text =
            settings['fakeCallPhoneNumber'] as String? ??
                UserProfileService.defaultFakeCallPhoneNumber;
        _voiceSosMessageController.text =
            settings['voiceSosEmergencyMessage'] as String? ??
                UserProfileService.defaultVoiceSosEmergencyMessage;
        _voiceSosEnabled = settings['voiceSosEnabled'] == true;
        _secretPhraseEnabled = settings['secretPhraseEnabled'] == true;
        _fakeCallVolumeShortcutEnabled =
            settings['fakeCallVolumeShortcutEnabled'] == true;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not load settings.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.userProfileService.saveFakeCallVoiceSettings(
        secretPhrase: _secretPhraseController.text,
        fakeCallContactName: _callerNameController.text,
        fakeCallPhoneNumber: _callerNumberController.text,
        voiceSosEmergencyMessage: _voiceSosMessageController.text,
        voiceSosEnabled: _voiceSosEnabled,
        secretPhraseEnabled: _secretPhraseEnabled,
        fakeCallVolumeShortcutEnabled: _fakeCallVolumeShortcutEnabled,
      );
      await widget.fakeCallShortcutService.syncShortcutMonitor();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } on UserProfileException catch (error) {
      _showSaveError(error.message);
    } catch (_) {
      _showSaveError('Could not save settings. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSaveError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Loading settings'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Fake Call',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _fakeCallVolumeShortcutEnabled,
              onChanged: (value) {
                setState(() => _fakeCallVolumeShortcutEnabled = value);
              },
              title: const Text('Volume-up shortcut'),
              subtitle: const Text(
                'When enabled, Amica keeps a safety shortcut notification running. Press volume up three times to open the call screen.',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _callerNameController,
              decoration: const InputDecoration(
                labelText: 'Fake caller name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a caller name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _callerNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Fake caller number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a caller number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Stealth Voice SOS',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _voiceSosEnabled,
              onChanged: (value) {
                setState(() => _voiceSosEnabled = value);
              },
              title: const Text('Enable voice SOS'),
              subtitle: const Text(
                'Listen for the secret phrase during an active fake call.',
              ),
            ),
            SwitchListTile(
              value: _secretPhraseEnabled,
              onChanged: (value) {
                setState(() => _secretPhraseEnabled = value);
              },
              title: const Text('Enable secret phrase'),
              subtitle:
                  const Text('Use the phrase below to trigger Voice SOS.'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _secretPhraseController,
              decoration: const InputDecoration(
                labelText: 'Secret phrase',
                helperText: 'Example: amica help me',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a secret phrase.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _voiceSosMessageController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'SOS message for emergency contact',
                helperText:
                    'Saved with the Voice SOS alert when the phrase is spoken.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the message to send.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Settings',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveSettings,
            ),
          ],
        ),
      ),
    );
  }
}
