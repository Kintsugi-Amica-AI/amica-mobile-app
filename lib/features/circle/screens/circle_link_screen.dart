import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/guardian_link_service.dart';

/// "Get alerts for someone": the contact's side of linking.
///
/// She texts them a code from her Circle screen; entering it here means her
/// SOS and live journeys arrive on this phone as notifications, with one-tap
/// replies, as well as by SMS.
class CircleLinkScreen extends StatefulWidget {
  const CircleLinkScreen({
    super.key,
    this.service = const GuardianLinkService(),
  });

  final GuardianLinkService service;

  @override
  State<CircleLinkScreen> createState() => _CircleLinkScreenState();
}

class _CircleLinkScreenState extends State<CircleLinkScreen> {
  final TextEditingController _code = TextEditingController();
  bool _linking = false;
  String? _error;
  List<GuardedPerson>? _guarding;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await widget.service.listGuarding();
      if (mounted) {
        setState(() {
          _guarding = list;
          _loadFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _link() async {
    final loc = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (code.replaceAll(RegExp(r'[\s-]'), '').length != 6) {
      setState(() => _error = loc.circleLinkCodeInvalid);
      return;
    }
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      final owner = await widget.service.acceptInvite(code);
      if (!mounted) return;
      _code.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.circleLinkLinked(owner.isEmpty ? loc.pushSomeone : owner),
          ),
        ),
      );
      await _load();
    } on GuardianLinkException catch (error) {
      if (!mounted) return;
      setState(() => _error = switch (error.reason) {
            'not_found' => loc.circleLinkErrorNotFound,
            'expired' => loc.circleLinkErrorExpired,
            'used' => loc.circleLinkErrorUsed,
            'own_invite' => loc.circleLinkErrorOwn,
            _ => error.message,
          });
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _unlink(GuardedPerson person) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.circleLinkStopTitle(person.ownerName)),
        content: Text(loc.circleLinkStopBody(person.ownerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.circleLinkStopConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.unlink(person.contactId);
      await _load();
    } on GuardianLinkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final guarding = _guarding;

    return Scaffold(
      appBar: AppBar(title: Text(loc.circleLinkTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(loc.circleLinkIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            AmicaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(loc.circleLinkCodeLabel, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _code,
                    enabled: !_linking,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 7,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
                    ],
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'ABC234',
                      counterText: '',
                      errorText: _error,
                      errorMaxLines: 3,
                    ),
                    onSubmitted: (_) => _link(),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: loc.circleLinkButton,
                    icon: Icons.link_rounded,
                    isBusy: _linking,
                    onPressed: _linking ? null : _link,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionLabel(loc.circleLinkGuardingTitle),
            const SizedBox(height: 10),
            if (_loadFailed)
              Text(loc.circleLinkLoadFailed, style: theme.textTheme.bodySmall)
            else if (guarding == null)
              const Center(child: CircularProgressIndicator())
            else if (guarding.isEmpty)
              Text(loc.circleLinkGuardingEmpty, style: theme.textTheme.bodySmall)
            else
              for (final person in guarding)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AmicaCard(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    child: Row(
                      children: [
                        AmicaAvatar(
                          initial: person.ownerName,
                          size: 40,
                          background: c.accentSoft,
                          foreground: c.accentInk,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.ownerName.isEmpty
                                    ? loc.pushSomeone
                                    : person.ownerName,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                loc.circleLinkGuardingSubtitle,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _unlink(person),
                          child: Text(loc.circleLinkStop),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
