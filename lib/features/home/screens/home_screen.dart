import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../widgets/safety_feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      SafetyFeatureCard(
        title: AppStrings.emergencyContacts,
        icon: Icons.contacts,
        onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
      ),
      SafetyFeatureCard(
        title: AppStrings.journeyTimer,
        icon: Icons.timer,
        onTap: () => Navigator.pushNamed(context, AppRoutes.startJourney),
      ),
      SafetyFeatureCard(
        title: AppStrings.liveSos,
        icon: Icons.sos,
        onTap: () => Navigator.pushNamed(context, AppRoutes.sosActive),
      ),
      SafetyFeatureCard(
        title: AppStrings.fakeCall,
        icon: Icons.phone,
        onTap: () => Navigator.pushNamed(context, AppRoutes.fakeCall),
      ),
      SafetyFeatureCard(
        title: AppStrings.plateScan,
        icon: Icons.document_scanner,
        onTap: () => Navigator.pushNamed(context, AppRoutes.plateScan),
      ),
      SafetyFeatureCard(
        title: 'Profile',
        icon: Icons.person,
        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: features,
      ),
    );
  }
}
