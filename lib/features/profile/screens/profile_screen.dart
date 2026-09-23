import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_primitives.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/theme_mode_selector.dart';
import '../../auth/models/app_user.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/user_profile_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/phone_verification_sheet.dart';
import '../../emergency_contacts/services/emergency_contact_service.dart';

/// The "You" tab.
///
/// Two changes of substance beyond the restyle.
///
/// First, setup is a visible checklist rather than a set of fields buried
/// in Settings. A woman should be able to tell in one glance whether this
/// app will actually work for her tonight — a half-configured safety app
/// that looks finished is worse than one that admits what is missing. Every
/// unfinished item has a working "Add" that takes her straight to the fix.
///
/// Second, **Log out lives here.** It used to sit in the home app bar, one
/// tap from the SOS button.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.authService = const AuthService(),
    this.contactService = const EmergencyContactService(),
    this.userProfileService = const UserProfileService(),
  });

  final AuthService authService;
  final EmergencyContactService contactService;
  final UserProfileService userProfileService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Live: follows the Firestore user document, so an edit, a verified
  /// phone number or a new voice phrase shows up the moment it is saved —
  /// no manual refresh, and no stale copy left behind in another tab.
  late final Stream<AppUser?> _profile =
      widget.authService.watchCurrentUserProfile();

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, AppRoutes.settings);
  }

  Future<void> _verifyPhone(AppUser? user) async {
    final verified = await showPhoneVerificationSheet(
      context,
      initialPhone: user?.phone ?? '',
    );
    if (verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).phoneVerified)),
      );
    }
  }

  Future<void> _editProfile(AppUser? user, {bool focusNotes = false}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditProfileSheet(
        user: user,
        focusNotes: focusNotes,
        service: widget.userProfileService,
        onVerifyPhone: () => _verifyPhone(user),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(loc.profileAppBarTitle),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<AppUser?>(
          stream: _profile,
          builder: (context, snapshot) {
            if (snapshot.hasError && !snapshot.hasData) {
              // Say so, rather than showing an empty profile that looks as
              // if her details were never saved.
              debugPrint('Profile stream error: ${snapshot.error}');
              return AmicaEmptyState(
                icon: Icons.cloud_off_rounded,
                title: loc.profileLoadFailedTitle,
                message: loc.profileLoadFailedBody,
              );
            }
            if (!snapshot.hasData) {
              return LoadingView(message: loc.profileLoadingYourProfile);
            }

            final user = snapshot.data;

            return StreamBuilder<List<EmergencyContact>>(
              stream: widget.contactService.watchEmergencyContacts(),
              builder: (context, contactSnap) {
                final guardians =
                    (contactSnap.data ?? []).where((g) => g.isActive).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  children: [
                    _Identity(
                      user: user,
                      onEdit: () => _editProfile(user),
                    ),
                    const SizedBox(height: 24),
                    _SetupChecklist(
                      user: user,
                      guardianCount: guardians.length,
                      onAddGuardian: () => Navigator.pushNamed(
                        context,
                        AppRoutes.addEmergencyContact,
                      ),
                      onAddVoicePhrase: _openSettings,
                      onAddPhone: () => _verifyPhone(user),
                      onAddMedicalNotes: () =>
                          _editProfile(user, focusNotes: true),
                    ),
                    const SizedBox(height: 24),
                    SectionLabel(loc.profileSectionHowAmicaBehaves),
                    const SizedBox(height: 4),
                    const _AppearanceRow(),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.mic_none_rounded,
                      title: loc.profileVoicePhrase,
                      subtitle: user?.secretPhrase?.trim().isNotEmpty == true
                          ? loc.profileVoicePhraseSet(user!.secretPhrase!)
                          : loc.profileVoicePhraseNotSet,
                      onTap: _openSettings,
                    ),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.lock_outline_rounded,
                      title: loc.profilePrivacyTitle,
                      subtitle: loc.profilePrivacySubtitle,
                      onTap: _openSettings,
                    ),
                    const AmicaDivider(),
                    AmicaListRow(
                      icon: Icons.tune_rounded,
                      title: loc.profileAllSettings,
                      onTap: _openSettings,
                    ),
                    const SizedBox(height: 28),
                    _LogoutButton(authService: widget.authService),
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

/// A small pill-shaped button — the tappable sibling of [StatusPill].
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.warm = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Warm (peach/gold) for "still to do"; otherwise lavender.
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final bg = warm ? c.goldSoft : c.accentSoft;
    final fg = warm ? c.gold : c.accentInk;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          // 44px tall hit area even though the pill looks compact.
          constraints: const BoxConstraints(minHeight: 34, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user, required this.onEdit});

  final AppUser? user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final name = user?.name.trim() ?? '';

    return AmicaCard(
      padding: const EdgeInsets.all(16),
      onTap: onEdit,
      child: Row(
        children: [
          // Gradient ring around the initial, the one decorative flourish on
          // this screen.
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: c.accentGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.card),
              child: AmicaAvatar(
                initial: name.isEmpty ? 'A' : name,
                size: 56,
              ),
            ),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user?.phone.trim().isNotEmpty == true
                            ? user!.phone
                            : user?.email ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: c.plum45,
                        ),
                      ),
                    ),
                    if (user?.phoneVerified == true) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded, size: 14, color: c.sage),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _PillButton(
            label: loc.commonEdit,
            icon: Icons.edit_rounded,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Honest about what is not done yet — and one tap from fixing it.
class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({
    required this.user,
    required this.guardianCount,
    required this.onAddGuardian,
    required this.onAddVoicePhrase,
    required this.onAddPhone,
    required this.onAddMedicalNotes,
  });

  final AppUser? user;
  final int guardianCount;
  final VoidCallback onAddGuardian;
  final VoidCallback onAddVoicePhrase;
  final VoidCallback onAddPhone;
  final VoidCallback onAddMedicalNotes;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

    final items = <({String label, bool done, IconData icon, VoidCallback onAdd})>[
      (
        label: guardianCount > 0
            ? loc.profileGuardiansInCircle(guardianCount)
            : loc.profileNoGuardiansYet,
        done: guardianCount > 0,
        icon: Icons.people_alt_outlined,
        onAdd: onAddGuardian,
      ),
      (
        label: loc.profileVoicePhraseRecorded,
        done: user?.secretPhrase?.trim().isNotEmpty == true,
        icon: Icons.mic_none_rounded,
        onAdd: onAddVoicePhrase,
      ),
      (
        label: user?.phoneVerified == true
            ? loc.profilePhoneConfirmed
            : loc.profilePhoneNotVerified,
        done: user?.phoneVerified == true,
        icon: Icons.phone_outlined,
        onAdd: onAddPhone,
      ),
      (
        label: loc.profileMedicalNotes,
        done: user?.medicalNotes.isNotEmpty == true,
        icon: Icons.medical_information_outlined,
        onAdd: onAddMedicalNotes,
      ),
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
              // Overall progress, as a soft gradient bar.
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: done / items.length,
                    minHeight: 6,
                    backgroundColor: c.accentSoft,
                    valueColor: AlwaysStoppedAnimation(
                      done == items.length ? c.sage : c.accent,
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const AmicaDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: items[i].done ? c.sageSoft : c.goldSoft,
                        ),
                        child: Icon(
                          items[i].done ? Icons.check_rounded : items[i].icon,
                          size: 17,
                          color: items[i].done ? c.sage : c.gold,
                        ),
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
                        _PillButton(
                          label: items[i].onAdd == onAddPhone
                              ? loc.profileVerifyAction
                              : loc.commonAdd,
                          icon: Icons.add_rounded,
                          warm: true,
                          onTap: items[i].onAdd,
                        ),
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

/// Edits the name, phone number and medical notes. Pops `true` once saved.
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.user,
    required this.focusNotes,
    required this.service,
    required this.onVerifyPhone,
  });

  final AppUser? user;
  final bool focusNotes;
  final UserProfileService service;

  /// Opens SMS verification. The number is never saved unverified.
  final VoidCallback onVerifyPhone;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name ?? '');
  late final _notes =
      TextEditingController(text: widget.user?.medicalNotes ?? '');
  final _notesFocus = FocusNode();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.focusNotes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notesFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateProfile(
        name: _name.text,
        medicalNotes: _notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on UserProfileException catch (error) {
      debugPrint('Profile save failed: ${error.message}');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppLocalizations.of(context)
            .profileSaveFailedWithCode(error.message);
      });
    } catch (error) {
      debugPrint('Profile save failed: $error');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = AppLocalizations.of(context).profileSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = theme.amica;

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.profileEditTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(loc.profileEditSubtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: loc.profileNameLabel,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? loc.profileNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                // Phone: shown read-only with its status; changing it goes
                // through SMS verification.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, color: c.plum45),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user?.phone.trim().isNotEmpty == true
                                    ? widget.user!.phone
                                    : loc.profilePhoneLabel,
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                widget.user?.phoneVerified == true
                                    ? loc.phoneVerifiedBadge
                                    : loc.phoneNotVerified,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.user?.phoneVerified == true
                                      ? c.sage
                                      : c.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  widget.onVerifyPhone();
                                },
                          child: Text(
                            widget.user?.phoneVerified == true
                                ? loc.phoneChangeNumber
                                : loc.profileVerifyAction,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  focusNode: _notesFocus,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: loc.profileMedicalNotesLabel,
                    hintText: loc.profileMedicalNotesHint,
                    prefixIcon: const Icon(Icons.medical_information_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!, style: TextStyle(color: c.terracottaDeep)),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: loc.commonSave,
                  icon: Icons.check_rounded,
                  isBusy: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Light · Dark · System. Dark doubles as discreet mode.
class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmicaListRow(
            icon: Icons.palette_outlined,
            title: loc.appearanceTitle,
            subtitle: loc.appearanceSubtitle,
            showChevron: false,
          ),
          const SizedBox(height: 4),
          const ThemeModeSelector(),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);

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
    final loc = AppLocalizations.of(context);
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
