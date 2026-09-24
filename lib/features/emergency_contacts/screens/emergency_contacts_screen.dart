import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../circle/widgets/connect_contact_sheet.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import 'add_emergency_contact_screen.dart';

/// "Your circle": the people Amica reaches first.
///
/// Laid out like the website mock-up: a large title and one-line promise,
/// a summary card with the guardians' initials stacked, then one calm card
/// per guardian with a single status pill (Primary / Linked / Muted) and a
/// full-width "Add a guardian" button at the end of the list.
///
/// The per-guardian controls (alerts on/off, connect in Amica, edit,
/// remove) live in a sheet opened by tapping the card, so the list itself
/// stays as quiet as the design.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({
    super.key,
    this.service = const EmergencyContactService(),
    this.isTab = false,
  });

  final EmergencyContactService service;

  /// True inside the bottom-nav shell: no app bar, the big title sits at
  /// the top. Pushed as its own route it keeps a back arrow.
  final bool isTab;

  /// The same rule the SOS call uses
  /// ([EmergencyContactService.getPrimaryActiveEmergencyContact]): the
  /// active guardian with the lowest priority, then by name.
  static EmergencyContact? primaryOf(List<EmergencyContact> contacts) {
    final active = contacts
        .where((c) => c.isActive && c.phone.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        final p = a.priority.compareTo(b.priority);
        if (p != 0) return p;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return active.isEmpty ? null : active.first;
  }

  void _addGuardian(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.addEmergencyContact);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bottomInset = 100 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: isTab
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
      body: SafeArea(
        top: isTab,
        // The list scrolls under the floating nav pill (like Home) rather
        // than stopping above an empty strip.
        bottom: false,
        child: StreamBuilder<List<EmergencyContact>>(
          stream: service.watchEmergencyContacts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const _Header(),
                  Expanded(child: LoadingView(message: loc.contactsLoading)),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          loc.contactsLoadError('${snapshot.error}'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final contacts = snapshot.data ?? const <EmergencyContact>[];
            if (contacts.isEmpty) {
              return Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: AmicaEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: loc.contactsEmptyTitle,
                      message: loc.contactsEmptyMessage,
                      action: SizedBox(
                        width: 250,
                        child: PrimaryButton(
                          label: loc.contactsAddFirstGuardian,
                          icon: Icons.person_add_alt_1_rounded,
                          onPressed: () => _addGuardian(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final primary = primaryOf(contacts);
            // Primary first, then the other active guardians, muted last.
            final ordered = [...contacts]..sort((a, b) {
                int rank(EmergencyContact c) =>
                    c.id == primary?.id ? 0 : (c.isActive ? 1 : 2);
                final r = rank(a).compareTo(rank(b));
                if (r != 0) return r;
                final p = a.priority.compareTo(b.priority);
                if (p != 0) return p;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

            return ListView(
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset),
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: _SummaryCard(contacts: ordered),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 20, 10),
                  child: SectionLabel(loc.contactsGuardiansSection),
                ),
                for (var i = 0; i < ordered.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 120 + 50 * i),
                      child: _GuardianCard(
                        contact: ordered[i],
                        // Same index as the summary card's stack, so a
                        // guardian keeps one colour across the screen.
                        palette: _GuardianPalette.of(
                          context,
                          i,
                          isActive: ordered[i].isActive,
                        ),
                        isPrimary: ordered[i].id == primary?.id,
                        onTap: () => _showGuardianSheet(
                          context,
                          ordered[i],
                          service,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: PrimaryButton(
                    label: loc.contactsAddGuardianButton,
                    icon: Icons.add_rounded,
                    onPressed: () => _addGuardian(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: FadeSlideIn(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                loc.contactsAppBarTitle,
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.contactsSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).amica.plum70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Colours per guardian ───────────────────────────────────────────────

/// A soft tint + ink pair so each guardian is recognisable at a glance, as
/// in the design. Rose-red is skipped on purpose: in Amica it only ever
/// means emergency, so the first guardian gets orchid instead.
class _GuardianPalette {
  const _GuardianPalette(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static _GuardianPalette of(
    BuildContext context,
    int index, {
    required bool isActive,
  }) {
    final c = Theme.of(context).amica;
    if (!isActive) return _GuardianPalette(c.shell, c.plum45);
    final pairs = [
      _GuardianPalette(c.orchidSoft, c.orchidInk),
      _GuardianPalette(c.sageSoft, c.sageInk),
      _GuardianPalette(c.sky, c.skyInk),
      _GuardianPalette(c.goldSoft, c.gold),
      _GuardianPalette(c.accentSoft, c.accentInk),
    ];
    return pairs[(index < 0 ? 0 : index) % pairs.length];
  }
}

// ── Summary card ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.contacts});

  /// Already ordered (primary first).
  final List<EmergencyContact> contacts;

  static const double _size = 50;
  static const double _overlap = 14;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final active = contacts.where((g) => g.isActive).toList();
    final linked = active.where((g) => g.isLinkedInAmica).length;
    final shown = (active.isEmpty ? contacts : active).take(3).toList();
    final extra = (active.isEmpty ? contacts : active).length - shown.length;
    final bubbles = shown.length + (extra > 0 ? 1 : 0);

    Widget ringed(Widget child) => Container(
          width: _size,
          height: _size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
          child: child,
        );

    return AmicaCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
      child: Row(
        children: [
          SizedBox(
            width: _size + (bubbles - 1) * (_size - _overlap),
            height: _size,
            child: Stack(
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * (_size - _overlap),
                    child: ringed(
                      AmicaAvatar(
                        initial: shown[i].name,
                        size: _size - 6,
                        background: _GuardianPalette.of(
                          context,
                          contacts.indexOf(shown[i]),
                          isActive: shown[i].isActive,
                        ).background,
                        foreground: _GuardianPalette.of(
                          context,
                          contacts.indexOf(shown[i]),
                          isActive: shown[i].isActive,
                        ).foreground,
                      ),
                    ),
                  ),
                if (extra > 0)
                  Positioned(
                    left: shown.length * (_size - _overlap),
                    child: ringed(
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.shell,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '+$extra',
                          style: TextStyle(
                            color: c.plum70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  active.isEmpty
                      ? loc.contactsNoneReady
                      : loc.contactsGuardiansReady(active.length),
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16.5),
                ),
                const SizedBox(height: 2),
                Text(
                  linked == 0
                      ? loc.contactsNoneLinked
                      : loc.contactsLinkedCount(linked),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guardian card ──────────────────────────────────────────────────────

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({
    required this.contact,
    required this.palette,
    required this.isPrimary,
    required this.onTap,
  });

  final EmergencyContact contact;
  final _GuardianPalette palette;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    final String detail;
    final Widget pill;
    if (!contact.isActive) {
      detail = loc.contactsMuted;
      pill = StatusPill(label: loc.contactsPillMuted);
    } else if (isPrimary) {
      detail = contact.isLinkedInAmica
          ? loc.contactsDetailPrimaryLinked
          : loc.contactsDetailPrimary;
      pill = StatusPill(label: loc.contactsPillPrimary, tone: PillTone.accent);
    } else if (contact.isLinkedInAmica) {
      detail = loc.contactsDetailLinked;
      pill = StatusPill(label: loc.contactsPillLinked, tone: PillTone.sage);
    } else {
      detail = loc.contactsDetailSmsOnly;
      pill = StatusPill(label: loc.contactsPillSms);
    }

    return Semantics(
      button: true,
      label: '${contact.name}. $detail',
      excludeSemantics: true,
      child: AmicaCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: [
            AmicaAvatar(
              initial: contact.name,
              size: 52,
              background: palette.background,
              foreground: palette.foreground,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: contact.isActive ? c.plum70 : c.plum45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            pill,
          ],
        ),
      ),
    );
  }
}

// ── Guardian actions sheet ─────────────────────────────────────────────

Future<void> _showGuardianSheet(
  BuildContext context,
  EmergencyContact contact,
  EmergencyContactService service,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => _GuardianSheet(
      contact: contact,
      service: service,
      hostContext: context,
    ),
  );
}

class _GuardianSheet extends StatefulWidget {
  const _GuardianSheet({
    required this.contact,
    required this.service,
    required this.hostContext,
  });

  final EmergencyContact contact;
  final EmergencyContactService service;

  /// The screen's context — still mounted after the sheet closes, so
  /// snackbars and pushed routes have somewhere to go.
  final BuildContext hostContext;

  @override
  State<_GuardianSheet> createState() => _GuardianSheetState();
}

class _GuardianSheetState extends State<_GuardianSheet> {
  late bool _active = widget.contact.isActive;
  bool _saving = false;

  void _snack(String message) {
    final host = widget.hostContext;
    if (!host.mounted) return;
    ScaffoldMessenger.of(host).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleActive(bool value) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _active = value;
      _saving = true;
    });
    try {
      await widget.service.setContactActive(widget.contact.id, value);
    } on EmergencyContactServiceException catch (error) {
      if (mounted) setState(() => _active = !value);
      _snack(error.message);
    } catch (_) {
      if (mounted) setState(() => _active = !value);
      _snack(loc.contactsCouldNotUpdate);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit() async {
    final host = widget.hostContext;
    Navigator.pop(context);
    await Navigator.push(
      host,
      MaterialPageRoute<void>(
        builder: (_) => AddEmergencyContactScreen(contact: widget.contact),
      ),
    );
  }

  void _connect() {
    Navigator.pop(context);
    showConnectContactSheet(widget.hostContext, widget.contact);
  }

  Future<void> _delete() async {
    final host = widget.hostContext;
    final loc = AppLocalizations.of(context);
    final contact = widget.contact;
    Navigator.pop(context);

    final shouldDelete = await showDialog<bool>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.contactsDeleteConfirmTitle),
        content: Text(loc.contactsDeleteConfirmBody(contact.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    try {
      await widget.service.deleteEmergencyContact(contact.id);
      _snack(loc.contactsDeleted);
    } on EmergencyContactServiceException catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack(loc.contactsCouldNotDelete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final contact = widget.contact;
    final linked = contact.isLinkedInAmica;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  AmicaAvatar(initial: contact.name, size: 44),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (contact.relationship.isNotEmpty)
                              contact.relationship,
                            contact.phone,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: c.plum70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              value: _active,
              onChanged: _saving ? null : _toggleActive,
              title: Text(loc.contactsAlertsToggle),
              subtitle: Text(
                _active ? loc.contactsAlertedOnSos : loc.contactsMuted,
              ),
            ),
            ListTile(
              leading: Icon(
                linked
                    ? Icons.notifications_active_rounded
                    : Icons.add_link_rounded,
                color: linked ? c.sage : c.accentInk,
              ),
              title: Text(
                linked ? loc.contactsLinkedInAmica : loc.contactsConnectInAmica,
              ),
              onTap: _connect,
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: c.plum70),
              title: Text(loc.commonEdit),
              onTap: _edit,
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: c.plum70),
              title: Text(loc.contactsRemoveTooltip(contact.name)),
              onTap: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
