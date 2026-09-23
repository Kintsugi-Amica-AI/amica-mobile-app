import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/locale/locale_controller.dart';
import 'core/navigation/amica_route_observer.dart';
import 'core/navigation/amica_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/loading_view.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/circle/models/guardian_alert.dart';
import 'features/circle/screens/circle_link_screen.dart';
import 'features/circle/screens/guardian_alert_screen.dart';
import 'features/emergency_contacts/screens/add_emergency_contact_screen.dart';
import 'features/emergency_contacts/screens/emergency_contacts_screen.dart';
import 'features/fake_call/screens/fake_call_active_screen.dart';
import 'features/fake_call/screens/fake_call_screen.dart';
import 'features/fake_call/services/fake_call_shortcut_service.dart';
import 'features/journey/screens/journey_timer_screen.dart';
import 'features/journey/screens/safety_check_screen.dart';
import 'features/journey/screens/start_journey_screen.dart';
import 'features/plate_scan/screens/plate_result_screen.dart';
import 'features/plate_scan/screens/plate_scan_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'features/sos/screens/sos_active_screen.dart';
import 'features/stop_alert/screens/stop_alert_active_screen.dart';
import 'features/stop_alert/screens/stop_alert_setup_screen.dart';
import 'services/push_notification_service.dart';

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
    PushNotificationService.instance.start(navigatorKey: _navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AmicaThemeController.instance,
      builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
        valueListenable: AmicaLocaleController.instance,
        builder: (context, locale, _) => _buildApp(themeMode, locale),
      ),
    );
  }

  Widget _buildApp(ThemeMode themeMode, Locale? locale) {
    return MaterialApp(
      // Screens without an AppBar (Home, the maps) still need transparent,
      // correctly tinted system bars.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayFor(Theme.of(context).brightness),
        child: child ?? const SizedBox.shrink(),
      ),
      navigatorKey: _navigatorKey,
      navigatorObservers: [amicaRouteObserver],
      title: AppStrings.appName,
      theme: AppTheme.light,
      // Light ⇄ dark cross-fades instead of snapping.
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeInOutCubic,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AmicaLocaleController.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale != null) {
          for (final candidate in supported) {
            if (candidate.languageCode == deviceLocale.languageCode) {
              return candidate;
            }
          }
        }
        return const Locale('en');
      },
      home: StreamBuilder(
        stream: _authService.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: LoadingView(
                message: AppLocalizations.of(context).checkingLoginStatus,
              ),
            );
          }

          return snapshot.data == null
              ? const LoginScreen()
              : const AmicaShell();
        },
      ),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.home: (_) => const AmicaShell(),
        AppRoutes.emergencyContacts: (_) => const EmergencyContactsScreen(),
        AppRoutes.addEmergencyContact: (_) => const AddEmergencyContactScreen(),
        AppRoutes.startJourney: (_) => const StartJourneyScreen(),
        AppRoutes.journeyTimer: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return JourneyTimerScreen(journeyId: args is String ? args : null);
        },
        AppRoutes.safetyCheck: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return SafetyCheckScreen(
            arguments: args is SafetyCheckArguments ? args : null,
          );
        },
        AppRoutes.stopAlert: (_) => const StopAlertSetupScreen(),
        AppRoutes.stopAlertActive: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return StopAlertActiveScreen(
            arguments: args is StopAlertActiveArguments ? args : null,
          );
        },
        AppRoutes.sosActive: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return SosActiveScreen(
            arguments: args is SosActiveArguments ? args : null,
          );
        },
        AppRoutes.fakeCall: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return FakeCallScreen(
            arguments: args is FakeCallArguments ? args : null,
          );
        },
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
        AppRoutes.circleLink: (_) => const CircleLinkScreen(),
        AppRoutes.guardianAlert: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return GuardianAlertScreen(
            alert: args is GuardianAlert
                ? args
                : const GuardianAlert(type: 'sos'),
          );
        },
      },
    );
  }
}
