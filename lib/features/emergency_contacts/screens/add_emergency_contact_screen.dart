import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/emergency_contact.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/emergency_contact_service.dart';

class AddEmergencyContactScreen extends StatefulWidget {
  const AddEmergencyContactScreen({
    super.key,
    this.contact,
    this.service = const EmergencyContactService(),
  });

  final EmergencyContact? contact;
  final EmergencyContactService service;

  @override
  State<AddEmergencyContactScreen> createState() =>
      _AddEmergencyContactScreenState();
}

class _AddEmergencyContactScreenState extends State<AddEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _priorityController = TextEditingController(text: '1');

  bool _isSaving = false;
  bool _isImportingContact = false;
  String? _errorMessage;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();

    final contact = widget.contact;
    if (contact != null) {
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _relationshipController.text = contact.relationship;
      _priorityController.text = contact.priority.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final priority = int.tryParse(_priorityController.text.trim()) ?? 1;

    try {
      if (_isEditing) {
        final updatedContact = widget.contact!.copyWith(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          relationship: _relationshipController.text.trim(),
          priority: priority,
          updatedAt: DateTime.now(),
        );
        await widget.service.updateEmergencyContact(updatedContact);
      } else {
        await widget.service.addEmergencyContact(
          name: _nameController.text,
          phone: _phoneController.text,
          relationship: _relationshipController.text,
          priority: priority,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on EmergencyContactServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage =
            AppLocalizations.of(context)!.addContactCouldNotSave,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickFromContacts() async {
    setState(() {
      _isImportingContact = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        if (mounted) {
          setState(
            () => _errorMessage =
                AppLocalizations.of(context)!.addContactPermissionRequired,
          );
        }
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || !mounted) {
        return;
      }

      if (contact.phones.isEmpty) {
        setState(
          () => _errorMessage =
              AppLocalizations.of(context)!.addContactNoPhoneNumber,
        );
        return;
      }

      setState(() {
        _nameController.text = contact.displayName;
        _phoneController.text = contact.phones.first.number;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              AppLocalizations.of(context)!.addContactCouldNotImport,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingContact = false);
      }
    }
  }

  String? _required(BuildContext context, String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired(fieldName);
    }
    return null;
  }

  String? _validatePriority(BuildContext context, String? value) {
    final priority = int.tryParse(value?.trim() ?? '');
    if (priority == null || priority < 1) {
      return AppLocalizations.of(context)!.addContactPriorityInvalid;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isEditing ? loc.addContactEditTitle : loc.addContactAddTitle),
      ),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                OutlinedButton.icon(
                  onPressed: _isImportingContact ? null : _pickFromContacts,
                  icon: _isImportingContact
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.contact_page_outlined),
                  label: Text(
                    _isImportingContact
                        ? loc.addContactOpeningContacts
                        : loc.addContactImportFromPhone,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: loc.addContactNameLabel,
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) =>
                            _required(context, value, loc.addContactNameLabel),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.addContactPhoneLabel,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.call_outlined,
                        validator: (value) => _required(
                            context, value, loc.addContactPhoneLabel),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.addContactRelationshipLabel,
                        controller: _relationshipController,
                        prefixIcon: Icons.diversity_1_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.addContactPriorityLabel,
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.flag_outlined,
                        helperText: loc.addContactPriorityHelper,
                        validator: (value) => _validatePriority(context, value),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isSaving
                            ? loc.addContactSaving
                            : loc.addContactSaveButton,
                        icon: Icons.save_outlined,
                        onPressed: _isSaving ? null : _saveContact,
                      ),
                      TextButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        child: Text(loc.commonCancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
