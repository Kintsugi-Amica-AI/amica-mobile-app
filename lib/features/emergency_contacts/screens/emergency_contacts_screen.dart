import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'add_emergency_contact_screen.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({
    super.key,
    this.service = const EmergencyContactService(),
  });

  final EmergencyContactService service;

  Future<void> _openEditScreen(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddEmergencyContactScreen(contact: contact),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final loc = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.contactsDeleteConfirmTitle),
          content: Text(loc.contactsDeleteConfirmBody(contact.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.commonDelete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await service.deleteEmergencyContact(contact.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).contactsDeleted)),
        );
      }
    } on EmergencyContactServiceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).contactsCouldNotDelete,
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(
    BuildContext context,
    EmergencyContact contact,
    bool isActive,
  ) async {
    try {
      await service.setContactActive(contact.id, isActive);
    } on EmergencyContactServiceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).contactsCouldNotUpdate,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.contactsAppBarTitle),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<EmergencyContact>>(
            stream: service.watchEmergencyContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadingView(message: loc.contactsLoading);
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      loc.contactsLoadError('${snapshot.error}'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final contacts = snapshot.data ?? const <EmergencyContact>[];
              if (contacts.isEmpty) {
                return AmicaEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: loc.contactsEmptyTitle,
                  message: loc.contactsEmptyMessage,
                  action: SizedBox(
                    width: 250,
                    child: PrimaryButton(
                      label: loc.contactsAddFirstGuardian,
                      icon: Icons.person_add_alt_1_rounded,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.addEmergencyContact,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                itemCount: contacts.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        loc.contactsAlertedTogetherNote,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  final index = i - 1;
                  final contact = contacts[index];
                  return _EmergencyContactCard(
                    contact: contact,
                    onEdit: () => _openEditScreen(context, contact),
                    onDelete: () => _confirmDelete(context, contact),
                    onActiveChanged: (value) => _toggleActive(
                      context,
                      contact,
                      value,
                    ),
                  );
                },
              );
            },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        shape: const StadiumBorder(),
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.addEmergencyContact,
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
        label: Text(loc.contactsAddGuardianFab),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.onActiveChanged,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final relationshipText =
        contact.relationship.isEmpty ? null : contact.relationship;

    return AmicaCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          AmicaAvatar(
            initial: contact.name,
            size: 44,
            background: contact.isActive ? c.accentSoft : c.shell,
            foreground: contact.isActive ? c.accentInk : c.plum45,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (relationshipText != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        relationshipText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: c.plum45,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  contact.phone,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: c.plum70,
                  ),
                ),
                const SizedBox(height: 6),
                // "Priority 1" meant nothing to a user. Say what it does.
                Text(
                  contact.isActive
                      ? loc.contactsAlertedOnSos
                      : loc.contactsMuted,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: contact.isActive ? c.sage : c.plum45,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: contact.isActive, onChanged: onActiveChanged),
              const SizedBox(height: 2),
              IconButton(
                tooltip: loc.contactsRemoveTooltip(contact.name),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: c.plum45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
