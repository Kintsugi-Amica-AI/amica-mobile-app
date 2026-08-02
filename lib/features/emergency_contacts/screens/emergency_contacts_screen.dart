import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete contact?'),
          content: Text('Remove ${contact.name} from emergency contacts?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
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
          const SnackBar(content: Text('Contact deleted')),
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
          const SnackBar(content: Text('Could not delete contact')),
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
          const SnackBar(content: Text('Could not update contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Emergency Contacts')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: StreamBuilder<List<EmergencyContact>>(
            stream: service.watchEmergencyContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Loading emergency contacts');
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load emergency contacts.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final contacts = snapshot.data ?? const <EmergencyContact>[];
              if (contacts.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            color: AppColors.textSecondary,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No emergency contacts yet.\nAdd someone you trust before testing SOS alerts.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add contact',
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.addEmergencyContact,
        ),
        child: const Icon(Icons.add),
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
    final relationshipText = contact.relationship.isEmpty
        ? 'Relationship not set'
        : contact.relationship;
    final initial = contact.name.isEmpty ? '?' : contact.name[0].toUpperCase();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryButtonGradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(contact.phone,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(relationshipText,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Chip(
                label: Text(contact.isActive ? 'Active' : 'Inactive'),
                visualDensity: VisualDensity.compact,
                backgroundColor: (contact.isActive
                        ? AppColors.success
                        : AppColors.textMuted)
                    .withValues(alpha: 0.16),
                labelStyle: TextStyle(
                  color: contact.isActive
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Priority ${contact.priority}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Use for SOS'),
              const Spacer(),
              Switch(
                value: contact.isActive,
                onChanged: onActiveChanged,
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.alert),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
