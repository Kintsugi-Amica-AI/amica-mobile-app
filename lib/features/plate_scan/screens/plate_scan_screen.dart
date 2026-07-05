import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/primary_button.dart';

class PlateScanScreen extends StatelessWidget {
  const PlateScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan before you ride')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner, size: 72),
            const SizedBox(height: 16),
            const Text('Capture a vehicle number plate before a trip.'),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Show sample result',
              icon: Icons.search,
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.plateResult,
                arguments: 'UNKNOWN',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
