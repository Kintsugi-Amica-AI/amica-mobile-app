import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      body: const Center(
        child: Text('Trusted contacts will appear here.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.addEmergencyContact,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
