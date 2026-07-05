import 'package:flutter/material.dart';

class PlateResultScreen extends StatelessWidget {
  const PlateResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plateNumber =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle status')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              plateNumber,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('Status: Unknown'),
            const SizedBox(height: 12),
            const Text(
              'Vehicle checks will use backend and AI results once connected.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
