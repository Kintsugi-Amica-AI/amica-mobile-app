import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/app_user.dart';
import '../../auth/services/auth_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';

/// The "You" tab.
///
/// Two changes of substance beyond the restyle.
///
/// First, setup is a visible checklist rather than a set of fields buried
/// in Settings. A woman should be able to tell in one glance whether this
/// app will actually work for her tonight — a half-configured safety app
/// that looks finished is worse than one that admits what is missing.
///
/// Second, **Log out lives here.** It used to sit in the home app bar, one
/// tap from the SOS button.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.authService = const AuthService(),
    this.contactService = const EmergencyContactService(),
  });

  final AuthService authService;
  final EmergencyContactService contactService;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: c.ivory,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.profileAppBarTitle),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<AppUser?>(
          future: authService.currentUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingView(message: loc.profileLoadingYourProfile);
            }

            final user = snapshot.data;

            return StreamBuilder<List<EmergencyContact>>(
              stream: contactService.watchEmergencyContacts(),
              builder: (context, contactSnap) {
                final guardians =
                    (contactSnap.data ?? []).where((g) => g.isActive).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _Identity(user: user),
                    const SizedBox(height: 24),
                    _SetupChecklist(
                      user: user,
                      guardianCount: guardians.length,
                    ),
                    const SizedBox(height: 24),
                    SectionLabel(loc.profileSectionHowAmicaBehaves),
                    const SizedBox(height: 4),
                    const _DiscreetModeRow(),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.mic_none_rounded,
                      title: loc.profileVoicePhrase,
                      subtitle: user?.secretPhrase?.trim().isNotEmpty == true
                          ? loc.profileVoicePhraseSet(user!.secretPhrase!)
                          : loc.profileVoicePhraseNotSet,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.lock_outline_rounded,
                      title: loc.profilePrivacyTitle,
                      subtitle: loc.profilePrivacySubtitle,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.tune_rounded,
                      title: loc.profileAllSettings,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    const SizedBox(height: 28),
                    _LogoutButton(authService: authService),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final name = user?.name.trim() ?? '';

    return Row(
      children: [
        AmicaAvatar(
          initial: name.isEmpty ? 'A' : name,
          size: 62,
          background: c.blush,
          foreground: c.terracottaDeep,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.isEmpty ? loc.profileYourProfile : name,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(
                user?.phone.trim().isNotEmpty == true
                    ? user!.phone
                    : user?.email ?? '',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: c.plum45,
                ),
              ),
            ],
          ),
        ),
        StatusPill(label: loc.commonEdit),
      ],
    );
  }
}

/// Honest about what is not done yet.
class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({required this.user, required this.guardianCount});

  final AppUser? user;
  final int guardianCount;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context)!;

    final items = <({String label, bool done})>[
      (
        label: guardianCount > 0
            ? loc.profileGuardiansInCircle(guardianCount)
            : loc.profileNoGuardiansYet,
        done: guardianCount > 0,
      ),
      (
        label: loc.profileVoicePhraseRecorded,
        done: user?.secretPhrase?.trim().isNotEmpty == true,
      ),
      (
        label: loc.profilePhoneConfirmed,
        done: user?.phone.trim().isNotEmpty == true,
      ),
      (label: loc.profileMedicalNotes, done: false),
    ];

    final done = items.where((i) => i.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          loc.profileSectionYourSafetySetup,
          trailing: Text(
            loc.profileSetupDoneCount(done, items.length),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: done == items.length ? c.sage : c.gold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        AmicaCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const AmicaDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        items[i].done
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: items[i].done ? c.sage : c.gold,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.plum,
                          ),
                        ),
                      ),
                      if (!items[i].done)
                        StatusPill(label: loc.commonAdd, tone: PillTone.gold),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscreetModeRow extends StatelessWidget {
  const _DiscreetModeRow();

  @override
  Widget build(BuildContext context) {
    final controller = AmicaThemeController.instance;
    final loc = AppLocalizations.of(context)!;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, _, __) {
        final on = controller.isDiscreetIn(context);
        return AmicaListRow(
          icon: Icons.dark_mode_outlined,
          title: loc.profileDiscreetModeTitle,
          subtitle: loc.profileDiscreetModeSubtitle,
          showChevron: false,
          onTap: () => controller.setDiscreet(!on),
          trailing: Switch(
            value: on,
            onChanged: controller.setDiscreet,
          ),
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context)!;

    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirm(context),
        icon: const Icon(Icons.logout_rounded, size: 17),
        label: Text(loc.profileLogOut),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: c.terracottaDeep,
          side: BorderSide(color: c.line),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.profileLogOutConfirmTitle),
        content: Text(loc.profileLogOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(loc.profileStayLoggedIn),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(loc.profileLogOut),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await authService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    }
  }
}
