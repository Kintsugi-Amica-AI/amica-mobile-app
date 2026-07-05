import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/primary_button.dart';

class JourneyTimerScreen extends StatelessWidget {
  const JourneyTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const remaining = Duration(minutes: 20);

    return Scaffold(
      appBar: AppBar(title: const Text('Journey timer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Time remaining'),
            const SizedBox(height: 12),
            Text(
              DateTimeUtils.formatDuration(remaining),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'I arrived safely',
              icon: Icons.check_circle,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.safetyCheck,
              ),
              icon: const Icon(Icons.help_outline),
              label: const Text('Run safety check'),
            ),
          ],
        ),
      ),
    );
  }
}
