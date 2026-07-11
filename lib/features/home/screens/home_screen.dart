import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/location_service.dart';
import '../../auth/services/auth_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../widgets/safety_feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.authService = const AuthService(),
    this.locationService = const LocationService(),
    this.sosService = const SosService(),
  });

  final AuthService authService;
  final LocationService locationService;
  final SosService sosService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSendingSos = false;

  Future<void> _logout(BuildContext context) async {
    await widget.authService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  Future<void> _triggerManualSos(BuildContext context) async {
    if (_isSendingSos) {
      return;
    }

    setState(() => _isSendingSos = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending SOS alert...')),
    );

    try {
      final location = await widget.locationService.getCurrentLocationData();
      final alertId = await widget.sosService.createManualSosAlert(
        location: location,
      );

      if (!context.mounted) {
        return;
      }
      Navigator.pushNamed(
        context,
        AppRoutes.sosActive,
        arguments: SosActiveArguments(
          alertId: alertId,
          triggerType: 'manual',
          location: location,
        ),
      );
    } on LocationServiceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } on SosServiceException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create SOS alert')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingSos = false);
      }
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
        title: _isSendingSos ? 'Sending SOS...' : 'SOS Alert',
        subtitle: _isSendingSos
            ? 'Creating your live alert.'
            : 'Send a live safety alert.',
        icon: Icons.sos,
        onTap: () => _triggerManualSos(context),
      ),
      SafetyFeatureCard(
        title: 'Profile / Settings',
        subtitle: 'Update safety preferences.',
        icon: Icons.person,
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
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
        ],
      ),
    );
  }
}
