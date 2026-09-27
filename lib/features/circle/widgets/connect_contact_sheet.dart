import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../services/emergency_action_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../services/guardian_link_service.dart';

/// Owner side of linking a contact's Amica account.
///
/// Texts the contact a one-time code from her own SIM. Because only someone
/// holding that phone can read the code, entering it proves the account
/// belongs to the person she added — no phone verification needed.
Future<void> showConnectContactSheet(
  BuildContext context,
  EmergencyContact contact,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ConnectContactSheet(contact: contact),
  );
}

class ConnectContactSheet extends StatefulWidget {
  const ConnectContactSheet({
    super.key,
    required this.contact,
    this.service = const GuardianLinkService(),
    this.actions = const EmergencyActionService(),
  });

  final EmergencyContact contact;
  final GuardianLinkService service;
  final EmergencyActionService actions;

  @override
  State<ConnectContactSheet> createState() => _ConnectContactSheetState();
}

class _ConnectContactSheetState extends State<ConnectContactSheet> {
  bool _busy = false;
  String? _code;
  bool? _texted;
  String? _error;

  EmergencyContact get _contact => widget.contact;

  Future<void> _sendInvite() async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invite = await widget.service.createInvite(_contact.id);
      final name = (FirebaseAuth.instance.currentUser?.displayName ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .first;
      final message = name.isEmpty
          ? loc.circleInviteSmsNoName(invite.code)
          : loc.circleInviteSms(name, invite.code);
      var texted = false;
      try {
        await widget.actions.sendEmergencySms(
          phone: _contact.phone.replaceAll(RegExp(r'[\s\-()]'), ''),
          message: message,
        );
        texted = true;
      } catch (_) {/* The code is still shown so she can pass it on. */}
      if (!mounted) return;
      setState(() {
        _code = invite.code;
        _texted = texted;
      });
    } on GuardianLinkException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    try {
      await widget.service.unlink(_contact.id);
      if (mounted) Navigator.pop(context);
    } on GuardianLinkException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final name = _contact.name;
    final code = _code;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _contact.isLinkedInAmica
                  ? loc.circleConnectLinkedTitle(name)
                  : loc.circleConnectTitle(name),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _contact.isLinkedInAmica
                  ? loc.circleConnectLinkedBody(name)
                  : loc.circleConnectBody(name),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (code != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SelectableText(
                      code,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700,
                        color: c.accentInk,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: code)),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(loc.circleConnectCopyCode),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _texted == true
                    ? loc.circleConnectTexted(name)
                    : loc.circleConnectTextFailed(name),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _texted == true ? c.sage : c.terracottaDeep,
                ),
              ),
              const SizedBox(height: 14),
              PrimaryButton(
                label: loc.commonOk,
                onPressed: () => Navigator.pop(context),
              ),
            ] else if (_contact.isLinkedInAmica)
              PrimaryButton(
                label: loc.circleConnectDisconnect,
                icon: Icons.link_off_rounded,
                tone: AmicaButtonTone.quiet,
                isBusy: _busy,
                onPressed: _busy ? null : _disconnect,
              )
            else
              PrimaryButton(
                label: loc.circleConnectSendCode(name),
                icon: Icons.sms_outlined,
                isBusy: _busy,
                onPressed: _busy ? null : _sendInvite,
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: c.terracottaDeep)),
            ],
          ],
        ),
      ),
    );
  }
}
