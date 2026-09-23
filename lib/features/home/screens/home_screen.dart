import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/navigation/amica_shell.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/models/app_user.dart';
import '../../auth/services/auth_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';
import '../../sos/screens/sos_arming_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/sos_hold_button.dart';

/// The home surface.
///
/// Reordered around one question: what does she need in the two seconds
/// after she opens this? So the SOS sits in the lower half, inside the
/// thumb zone, at a size nothing else competes with — the old layout put it
/// mid-screen surrounded by four equally glowing feature cards.
///
/// Everything above it is reassurance rather than controls: what is armed
/// right now, and how many people can reach her. Everything below is the
/// quiet, non-alarming tools, deliberately small.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.authService = const AuthService(),
    this.contactService = const EmergencyContactService(),
  });

  final AuthService authService;
  final EmergencyContactService contactService;

  static String greetingFor(DateTime now, AppLocalizations loc) {
    if (now.hour < 12) return loc.greetingMorning;
    if (now.hour < 17) return loc.greetingAfternoon;
    return loc.greetingEvening;
  }

  static String firstNameOf(AppUser? user) {
    final name = user?.name.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<EmergencyContact>>(
          stream: contactService.watchEmergencyContacts(),
          builder: (context, contactSnap) {
            final guardians =
                (contactSnap.data ?? []).where((c) => c.isActive).toList();

            return StreamBuilder<AppUser?>(
              stream: authService.authStateChanges(),
              builder: (context, userSnap) {
                final firstName = firstNameOf(userSnap.data);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final loc = AppLocalizations.of(context);
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            _Header(
                              initial: firstName,
                              onProfile: () => Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                              ),
                            ),
                            _Greeting(
                              greeting: HomeScreen.greetingFor(DateTime.now(), loc),
                              firstName: firstName,
                              guardianCount: guardians.length,
                            ),
                            const SizedBox(height: 18),
                            _ProtectionStatus(guardianCount: guardians.length),
                            const SizedBox(height: 28),
                            _SosHero(guardians: guardians),
                            const SizedBox(height: 30),
                            _QuieterOptions(),
                            const SizedBox(height: 16),
                            const _SafetyTip(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.initial, required this.onProfile});

  final String initial;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final controller = AmicaThemeController.instance;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => c.accentGradient.createShader(bounds),
            child: Text(
              'Amica',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const Spacer(),
          // Discreet mode within reach of the screen she is on when she
          // needs it, not three levels down in settings.
          ValueListenableBuilder<ThemeMode>(
            valueListenable: controller,
            builder: (context, _, __) {
              final on = controller.isDiscreetIn(context);
              return Semantics(
                button: true,
                label:
                    on ? loc.discreetModeTurnOff : loc.discreetModeTurnOn,
                child: InkWell(
                  onTap: () => controller.setDiscreet(!on),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: on ? null : c.card,
                      gradient: on ? c.accentGradient : null,
                      shape: BoxShape.circle,
                      border: on ? null : Border.all(color: c.lineSoft),
                      boxShadow: c.shadow,
                    ),
                    child: Icon(
                      on ? Icons.dark_mode_rounded : Icons.dark_mode_outlined,
                      size: 19,
                      color: on ? AppColors.onAccent : c.accentInk,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.accentGradient,
              ),
              child: AmicaAvatar(
                initial: initial.isEmpty ? 'A' : initial,
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.firstName,
    required this.guardianCount,
  });

  final String greeting;
  final String firstName;
  final int guardianCount;

  /// Says how many people can reach her, in words, because a number alone
  /// ("3 contacts") reads as a database row rather than as company.
  String _subline(AppLocalizations loc) {
    if (guardianCount == 0) {
      return loc.homeNoGuardiansSubline;
    }
    return loc.homeGuardianCountSubline(guardianCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstName.isEmpty
                ? loc.homeGreetingNoName(greeting)
                : loc.homeGreetingWithName(greeting, firstName),
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(_subline(loc), style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Standing reassurance: what is actually armed right now.
///
/// Trust in a safety app is built before the emergency, not during it. If
/// she cannot tell at a glance whether location is on, she will not believe
/// the button works either.
class _ProtectionStatus extends StatelessWidget {
  const _ProtectionStatus({required this.guardianCount});

  final int guardianCount;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final ready = guardianCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AmicaCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ready ? c.sageSoft : c.goldSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ready ? Icons.verified_user_outlined : Icons.shield_outlined,
                size: 20,
                color: ready ? c.sage : c.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ready ? loc.homeYouAreProtected : loc.homeFinishSettingUp,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ready
                        ? loc.homeProtectionReadySubline(guardianCount)
                        : loc.homeAddGuardianPrompt,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: c.plum45,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.plum45),
          ],
        ),
      ),
    );
  }
}

class _SosHero extends StatelessWidget {
  const _SosHero({required this.guardians});

  final List<EmergencyContact> guardians;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SosHoldButton(
            onTriggered: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SosArmingScreen(guardians: guardians),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Text(
              loc.homeSosHoldHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: c.plum45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The non-alarm tools. Small, four across, visually quiet — these are for
/// the ordinary uneasy walk home, not the emergency.
class _QuieterOptions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(loc.homeSectionQuieterOptions),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AmicaTile(
                  label: loc.homeTileWalkWithMe,
                  icon: Icons.location_on_outlined,
                  tint: c.sageSoft,
                  iconColor: c.sage,
                  // Same feature as the Journeys tab, so open that tab
                  // rather than a duplicate screen with its own state.
                  onTap: () {
                    final shell = AmicaShellScope.maybeOf(context);
                    if (shell != null) {
                      shell.selectTab(AmicaShellScope.journeysTab);
                    } else {
                      Navigator.pushNamed(context, AppRoutes.startJourney);
                    }
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: AmicaTile(
                  label: loc.homeTileFakeCall,
                  icon: Icons.phone_outlined,
                  tint: c.goldSoft,
                  iconColor: c.gold,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.fakeCall),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: AmicaTile(
                  label: loc.homeTileScanPlate,
                  icon: Icons.qr_code_scanner_rounded,
                  tint: c.sky,
                  iconColor: c.skyInk,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.plateScan),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: AmicaTile(
                  label: loc.homeTileStopAlert,
                  icon: Icons.notifications_active_outlined,
                  tint: c.accentSoft,
                  iconColor: c.accentInk,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.stopAlert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A gentle daily safety tip, like the "tip of the day" card in the
/// reference designs. Rotates by calendar day so it feels fresh without
/// ever changing mid-glance.
class _SafetyTip extends StatelessWidget {
  const _SafetyTip();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final tips = [
      loc.homeSafetyTip1,
      loc.homeSafetyTip2,
      loc.homeSafetyTip3,
      loc.homeSafetyTip4,
      loc.homeSafetyTip5,
      loc.homeSafetyTip6,
    ];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final tip = tips[dayOfYear % tips.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AmicaCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: c.accentGradient,
                boxShadow: c.accentGlow,
              ),
              child: const Icon(
                Icons.tips_and_updates_outlined,
                size: 20,
                color: AppColors.onAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.homeSafetyTipTitle,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: c.accentInk)),
                  const SizedBox(height: 3),
                  Text(tip, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
