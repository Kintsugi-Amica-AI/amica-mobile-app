import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/safety_feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.authService = const AuthService(),
  });

  final AuthService authService;

  void _showTodo(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName will be connected in the next MVP step.')),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await authService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      SafetyFeatureCard(
        title: 'Start Journey',
        subtitle: 'Set a timer before you travel.',
        icon: Icons.timer,
        onTap: () => Navigator.pushNamed(context, AppRoutes.startJourney),
      ),
      SafetyFeatureCard(
        title: AppStrings.emergencyContacts,
        subtitle: 'Manage trusted contacts.',
        icon: Icons.contacts,
        onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
      ),
      SafetyFeatureCard(
        title: AppStrings.fakeCall,
        subtitle: 'Trigger a deterrent call.',
        icon: Icons.phone,
        onTap: () => Navigator.pushNamed(context, AppRoutes.fakeCall),
      ),
      SafetyFeatureCard(
        title: 'Scan Vehicle',
        subtitle: 'Check a number plate.',
        icon: Icons.document_scanner,
        onTap: () => Navigator.pushNamed(context, AppRoutes.plateScan),
      ),
      SafetyFeatureCard(
        title: 'SOS Alert',
        subtitle: 'Send a live safety alert.',
        icon: Icons.sos,
        onTap: () => Navigator.pushNamed(context, AppRoutes.sosActive),
      ),
      SafetyFeatureCard(
        title: 'Profile / Settings',
        subtitle: 'Update safety preferences.',
        icon: Icons.person,
        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hello, stay safe today',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Amica helps you share alerts, track journeys, and quickly reach trusted contacts.',
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: features,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showTodo(context, 'Live location sharing'),
            icon: const Icon(Icons.location_on),
            label: const Text('Test live location later'),
          ),
        ],
      ),
    );
  }
}
