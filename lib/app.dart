import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/navigation/amica_route_observer.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/loading_view.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/emergency_contacts/screens/add_emergency_contact_screen.dart';
import 'features/emergency_contacts/screens/emergency_contacts_screen.dart';
import 'features/fake_call/screens/fake_call_active_screen.dart';
import 'features/fake_call/screens/fake_call_screen.dart';
import 'features/fake_call/services/fake_call_shortcut_service.dart';
import 'features/home/screens/home_screen.dart';
import 'features/journey/screens/journey_timer_screen.dart';
import 'features/journey/screens/safety_check_screen.dart';
import 'features/journey/screens/start_journey_screen.dart';
import 'features/plate_scan/screens/plate_result_screen.dart';
import 'features/plate_scan/screens/plate_scan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/sos/screens/sos_active_screen.dart';

class AmicaApp extends StatefulWidget {
  const AmicaApp({super.key});

  @override
  State<AmicaApp> createState() => _AmicaAppState();
}

class _AmicaAppState extends State<AmicaApp> {
  static const AuthService _authService = AuthService();
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
  final FakeCallShortcutService _fakeCallShortcutService =
      FakeCallShortcutService();

  @override
  void initState() {
    super.initState();
    _fakeCallShortcutService.configure(navigatorKey: _navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      navigatorObservers: [amicaRouteObserver],
      title: AppStrings.appName,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: StreamBuilder(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: LoadingView(message: 'Checking login status'),
            );
          }

          return snapshot.data == null
              ? const LoginScreen()
              : const HomeScreen();
        },
      ),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.emergencyContacts: (_) => const EmergencyContactsScreen(),
        AppRoutes.addEmergencyContact: (_) => const AddEmergencyContactScreen(),
        AppRoutes.startJourney: (_) => const StartJourneyScreen(),
        AppRoutes.journeyTimer: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return JourneyTimerScreen(journeyId: args is String ? args : null);
        },
        AppRoutes.safetyCheck: (_) => const SafetyCheckScreen(),
        AppRoutes.sosActive: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return SosActiveScreen(
            arguments: args is SosActiveArguments ? args : null,
          );
        },
        AppRoutes.fakeCall: (_) => const FakeCallScreen(),
        AppRoutes.fakeCallActive: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return FakeCallActiveScreen(
            arguments: args is FakeCallActiveArguments ? args : null,
          );
        },
        AppRoutes.plateScan: (_) => PlateScanScreen(),
        AppRoutes.plateResult: (_) => const PlateResultScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => SettingsScreen(),
      },
    );
  }
}
