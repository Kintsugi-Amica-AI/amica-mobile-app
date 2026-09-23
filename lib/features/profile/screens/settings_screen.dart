import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/services/user_profile_service.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
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
        _errorMessage = AppLocalizations.of(context)!.settingsCouldNotLoad;
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
        SnackBar(content: Text(AppLocalizations.of(context)!.settingsSaved)),
      );
    } on UserProfileException catch (error) {
      _showSaveError(error.message);
    } catch (_) {
      _showSaveError(AppLocalizations.of(context)!.settingsCouldNotSave);
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
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AmicaBackground(
          child: SafeArea(
            child: LoadingView(message: loc.settingsLoading),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(loc.settingsAppBarTitle)),
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
                    style: TextStyle(color: Theme.of(context).amica.terracotta),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(Icons.phone_in_talk_outlined,
                        color: Theme.of(context).amica.gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.settingsFakeCallSection,
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
                        title: Text(loc.settingsVolumeShortcutTitle),
                        subtitle: Text(loc.settingsVolumeShortcutSubtitle),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _callerNameController,
                        decoration: InputDecoration(
                          labelText: loc.settingsFakeCallerNameLabel,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.settingsEnterCallerName;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _callerNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.settingsFakeCallerNumberLabel,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.settingsEnterCallerNumber;
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
                    Icon(Icons.record_voice_over_outlined,
                        color: Theme.of(context).amica.sage, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.settingsVoiceSosSection,
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
                        title: Text(loc.settingsEnableVoiceSos),
                        subtitle: Text(loc.settingsListenForPhrase),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _secretPhraseEnabled,
                        onChanged: (value) {
                          setState(() => _secretPhraseEnabled = value);
                        },
                        title: Text(loc.settingsEnableSecretPhrase),
                        subtitle: Text(loc.settingsUsePhraseBelow),
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
                                  labelText: loc.settingsSecretPhraseLabel(
                                      index + 1)),
                              validator: (value) {
                                final phrase =
                                    UserProfileService.normalizeSecretPhrase(
                                        value ?? '');
                                if (phrase.isEmpty) {
                                  return loc.settingsEnterPhrase;
                                }
                                if (_phraseControllers
                                        .where((c) =>
                                            UserProfileService
                                                .normalizeSecretPhrase(
                                                    c.text) ==
                                            phrase)
                                        .length >
                                    1) {
                                  return loc.settingsPhraseAlreadyListed;
                                }
                                return null;
                              },
                            )),
                            IconButton(
                              tooltip: loc.settingsRemovePhrase,
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
                        label: Text(loc.settingsAddPhrase),
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
                        decoration: InputDecoration(
                          labelText: loc.settingsSosMessageLabel,
                          helperText: loc.settingsSosMessageHelper,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.settingsEnterMessage;
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
                    Icon(Icons.language_rounded,
                        color: Theme.of(context).amica.terracotta, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.settingsLanguageSection,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loc.settingsLanguageSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: ValueListenableBuilder<Locale?>(
                    valueListenable: AmicaLocaleController.instance,
                    builder: (context, selected, _) {
                      // No selection yet means "follow the device language",
                      // shown as whichever supported locale that resolves
                      // to right now so exactly one option is always
                      // highlighted.
                      final effective = selected ??
                          Localizations.localeOf(context);
                      return Column(
                        children: [
                          for (final locale
                              in AmicaLocaleController.supportedLocales)
                            RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              value: locale.languageCode,
                              groupValue: effective.languageCode,
                              title: Text(
                                AmicaLocaleController
                                        .nativeNames[locale.languageCode] ??
                                    locale.languageCode,
                              ),
                              onChanged: (_) => AmicaLocaleController.instance
                                  .setLocale(locale),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isSaving ? loc.settingsSaving : loc.settingsSaveButton,
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
