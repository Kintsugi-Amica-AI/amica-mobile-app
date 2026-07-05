import 'package:flutter/material.dart';

import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CustomTextField(
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Send reset link',
            icon: Icons.mail,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
