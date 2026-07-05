import 'package:flutter/material.dart';

import '../../../core/widgets/primary_button.dart';

class FakeCallScreen extends StatelessWidget {
  const FakeCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fake call')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_in_talk, size: 72),
            const SizedBox(height: 16),
            const Text('Schedule a realistic incoming call as a deterrent.'),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Schedule fake call',
              icon: Icons.call,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
