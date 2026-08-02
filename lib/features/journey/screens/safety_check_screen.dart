import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';

class SafetyCheckScreen extends StatelessWidget {
  const SafetyCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Safety check')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.secondary,
                  size: 56,
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        'Confirm that you are safe.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'I am safe',
                        icon: Icons.verified_user_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.sosActive,
                        ),
                        icon: const Icon(Icons.sos_rounded),
                        label: const Text('Send SOS'),
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
