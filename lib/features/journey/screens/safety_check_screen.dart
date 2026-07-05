import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/primary_button.dart';

class SafetyCheckScreen extends StatelessWidget {
  const SafetyCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety check')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Confirm that you are safe.'),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'I am safe',
              icon: Icons.verified_user,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.sosActive,
              ),
              icon: const Icon(Icons.sos),
              label: const Text('Send SOS'),
            ),
          ],
        ),
      ),
    );
  }
}
