import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
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
  final _phraseControllers = <TextEditingController>[TextEditingController()];
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
    for (final controller in _phraseControllers) {
      controller.dispose();
    }
    _callerNameController.dispose();
    _callerNumberController.dispose();
    _voiceSosMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final phrases = await widget.userProfileService.getSecretPhrases();
      final settings = await widget.userProfileService.getSafetySettings();

      if (!mounted) {
        return;
      }

      setState(() {
        for (final controller in _phraseControllers) {
          controller.dispose();
        }
        _phraseControllers
          ..clear()
          ..addAll(
              phrases.map((phrase) => TextEditingController(text: phrase)));
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
        secretPhrase: _phraseControllers.first.text,
        secretPhrases: _phraseControllers.map((c) => c.text).toList(),
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
        backgroundColor: Colors.transparent,
        body: AmicaBackground(
          child: SafeArea(
            child: LoadingView(message: 'Loading settings'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Settings')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.alert),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Fake Call',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _fakeCallVolumeShortcutEnabled,
                        onChanged: (value) {
                          setState(
                              () => _fakeCallVolumeShortcutEnabled = value);
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a caller number.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.record_voice_over_outlined,
                        color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Stealth Voice SOS',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
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
                        contentPadding: EdgeInsets.zero,
                        value: _secretPhraseEnabled,
                        onChanged: (value) {
                          setState(() => _secretPhraseEnabled = value);
                        },
                        title: const Text('Enable secret phrase'),
                        subtitle: const Text(
                            'Use the phrase below to trigger Voice SOS.'),
                      ),
                      const SizedBox(height: 8),
                      for (var index = 0;
                          index < _phraseControllers.length;
                          index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Expanded(
                                child: TextFormField(
                              controller: _phraseControllers[index],
                              enabled: !_isSaving,
                              maxLength: 120,
                              decoration: InputDecoration(
                                  labelText: 'Secret phrase ${index + 1}'),
                              validator: (value) {
                                final phrase =
                                    UserProfileService.normalizeSecretPhrase(
                                        value ?? '');
                                if (phrase.isEmpty) return 'Enter a phrase.';
                                if (_phraseControllers
                                        .where((c) =>
                                            UserProfileService
                                                .normalizeSecretPhrase(
                                                    c.text) ==
                                            phrase)
                                        .length >
                                    1) {
                                  return 'This phrase is already in the list.';
                                }
                                return null;
                              },
                            )),
                            IconButton(
                              tooltip: 'Remove phrase',
                              onPressed: _isSaving ||
                                      _phraseControllers.length == 1
                                  ? null
                                  : () {
                                      final removed = _phraseControllers[index];
                                      setState(() =>
                                          _phraseControllers.removeAt(index));
                                      WidgetsBinding.instance
                                          .addPostFrameCallback(
                                              (_) => removed.dispose());
                                    },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ]),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add phrase'),
                        onPressed: _isSaving || _phraseControllers.length >= 10
                            ? null
                            : () => setState(() => _phraseControllers
                                .add(TextEditingController())),
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the message to send.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isSaving ? 'Saving...' : 'Save Settings',
                  icon: Icons.save_outlined,
                  onPressed: _isSaving ? null : _saveSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
