import 'package:flutter/material.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class AddEmergencyContactScreen extends StatelessWidget {
  const AddEmergencyContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add contact')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CustomTextField(label: 'Name'),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Phone number',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Relationship'),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Save contact',
            icon: Icons.save,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
