import 'package:flutter/material.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CustomTextField(label: 'Name'),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Password', obscureText: true),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Create account',
            icon: Icons.person_add,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
