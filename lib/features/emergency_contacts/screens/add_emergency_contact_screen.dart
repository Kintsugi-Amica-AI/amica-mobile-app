import 'package:flutter/material.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/emergency_contact.dart';
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
        () => _errorMessage = 'Could not save contact. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePriority(String? value) {
    final priority = int.tryParse(value?.trim() ?? '');
    if (priority == null || priority < 1) {
      return 'Priority must be a positive number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit contact' : 'Add contact'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            CustomTextField(
              label: 'Name',
              controller: _nameController,
              validator: (value) => _required(value, 'Name'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Phone number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) => _required(value, 'Phone number'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Relationship',
              controller: _relationshipController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Priority',
              controller: _priorityController,
              keyboardType: TextInputType.number,
              validator: _validatePriority,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSaving ? 'Saving...' : 'Save Contact',
              icon: Icons.save,
              onPressed: _isSaving ? null : _saveContact,
            ),
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
