import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../services/location_service.dart';
import '../../auth/services/auth_service.dart';
import '../../sos/screens/sos_active_screen.dart';
import '../../sos/services/sos_service.dart';
import '../widgets/pulsing_sos_button.dart';
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      SafetyFeatureCard(
        title: 'Start Journey',
        subtitle: 'Set a timer before you travel.',
        icon: Icons.timer_outlined,
        iconColor: AppColors.secondary,
        onTap: () => Navigator.pushNamed(context, AppRoutes.startJourney),
      ),
      SafetyFeatureCard(
        title: AppStrings.stopAlert,
        subtitle: 'Alarm before your bus stop.',
        icon: Icons.directions_bus_filled_outlined,
        iconColor: AppColors.secondary,
        onTap: () => Navigator.pushNamed(context, AppRoutes.stopAlert),
      ),
      SafetyFeatureCard(
        title: AppStrings.emergencyContacts,
        subtitle: 'Manage trusted contacts.',
        icon: Icons.contacts_outlined,
        iconColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyContacts),
      ),
      SafetyFeatureCard(
        title: AppStrings.fakeCall,
        subtitle: 'Ring now or schedule one.',
        icon: Icons.phone_in_talk_outlined,
        iconColor: AppColors.warning,
        onTap: () => Navigator.pushNamed(context, AppRoutes.fakeCall),
      ),
      SafetyFeatureCard(
        title: 'Scan Vehicle',
        subtitle: 'Check a number plate.',
        icon: Icons.document_scanner_outlined,
        iconColor: AppColors.success,
        onTap: () => Navigator.pushNamed(context, AppRoutes.plateScan),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AmicaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                '${_greeting()}, stay safe today',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Amica watches over your journeys and reaches trusted contacts the instant you need help.',
              ),
              const SizedBox(height: 28),
              Center(
                child: PulsingSosButton(
                  isBusy: _isSendingSos,
                  onTap: () => _triggerManualSos(context),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Safety toolkit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.98,
                children: features,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
