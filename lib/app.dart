import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/emergency_contacts/screens/add_emergency_contact_screen.dart';
import 'features/emergency_contacts/screens/emergency_contacts_screen.dart';
import 'features/fake_call/screens/fake_call_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journey/screens/journey_timer_screen.dart';
import 'features/journey/screens/safety_check_screen.dart';
import 'features/journey/screens/start_journey_screen.dart';
import 'features/plate_scan/screens/plate_result_screen.dart';
import 'features/plate_scan/screens/plate_scan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/sos/screens/sos_active_screen.dart';

class AmicaApp extends StatelessWidget {
  const AmicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.emergencyContacts: (_) => const EmergencyContactsScreen(),
        AppRoutes.addEmergencyContact: (_) => const AddEmergencyContactScreen(),
        AppRoutes.startJourney: (_) => const StartJourneyScreen(),
        AppRoutes.journeyTimer: (_) => const JourneyTimerScreen(),
        AppRoutes.safetyCheck: (_) => const SafetyCheckScreen(),
        AppRoutes.sosActive: (_) => const SosActiveScreen(),
        AppRoutes.fakeCall: (_) => const FakeCallScreen(),
        AppRoutes.plateScan: (_) => const PlateScanScreen(),
        AppRoutes.plateResult: (_) => const PlateResultScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
