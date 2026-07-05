import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amica')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CustomTextField(
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const CustomTextField(label: 'Password', obscureText: true),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Log in',
            icon: Icons.login,
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              AppRoutes.home,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.forgotPassword,
            ),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
