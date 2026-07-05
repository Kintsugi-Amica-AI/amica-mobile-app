import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';

class StartJourneyScreen extends StatelessWidget {
  const StartJourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start journey')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CustomTextField(label: 'Destination'),
          const SizedBox(height: 16),
          const CustomTextField(
            label: 'Expected duration in minutes',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Start timer',
            icon: Icons.play_arrow,
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.journeyTimer,
            ),
          ),
        ],
      ),
    );
  }
}
