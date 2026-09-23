import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/amica_logo.dart';
import '../../../core/widgets/auth_widgets.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.authService = const AuthService(),
  });

  final AuthService authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secretPhraseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _secretPhraseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signUpWithEmailAndPassword(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        secretPhrase: _secretPhraseController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = AppLocalizations.of(context).signupFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signInWithGoogle();

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = AppLocalizations.of(context).googleSignInFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).fieldRequired(fieldName);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.amica;
    final loc = AppLocalizations.of(context);

    // Same language as the login screen: transparent bar, small logo, one
    // frosted card. Google comes first (one tap), then the form in three
    // short, labelled groups so it never feels like a wall of fields.
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                children: [
                  FadeSlideIn(
                    offset: const Offset(0, 0.08),
                    child: Column(
                      children: [
                        const AmicaLogo(size: 84),
                        const SizedBox(height: 16),
                        Text(
                          loc.signupJoinAmica,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            loc.signupSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: c.plum70, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: AmicaCard(
                      borderRadius: 30,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GoogleSignInButton(
                            label: loc.continueWithGoogle,
                            isBusy: _isGoogleLoading,
                            onPressed: _isBusy ? null : _continueWithGoogle,
                          ),
                          const SizedBox(height: 18),
                          OrDivider(label: loc.loginOr),
                          const SizedBox(height: 18),

                          // ── About you ──
                          _GroupHeader(
                            icon: Icons.person_outline_rounded,
                            label: loc.signupSectionAboutYou,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: loc.signupNameLabel,
                            controller: _nameController,
                            prefixIcon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: (value) =>
                                _required(value, loc.signupNameLabel),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: loc.commonEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return loc.signupEmailInvalid;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: loc.signupPhoneLabel,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.call_outlined,
                            hintText: '07X XXX XXXX',
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            validator: (value) =>
                                _required(value, loc.signupPhoneLabel),
                          ),
                          const SizedBox(height: 22),

                          // ── Your safety ──
                          _GroupHeader(
                            icon: Icons.shield_outlined,
                            label: loc.signupSectionSafety,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: loc.signupSecretPhraseLabel,
                            controller: _secretPhraseController,
                            prefixIcon: Icons.record_voice_over_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                _required(value, loc.signupSecretPhraseLabel),
                          ),
                          const SizedBox(height: 10),
                          _HintNote(text: loc.signupSecretPhraseHelper),
                          const SizedBox(height: 22),

                          // ── Password ──
                          _GroupHeader(
                            icon: Icons.lock_outline_rounded,
                            label: loc.signupSectionPassword,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: loc.commonPassword,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            suffix: PasswordVisibilityButton(
                              obscured: _obscurePassword,
                              showLabel: loc.loginShowPassword,
                              hideLabel: loc.loginHidePassword,
                              onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return loc.signupPasswordTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _passwordController,
                            builder: (context, value, _) =>
                                _PasswordStrength(password: value.text),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: loc.signupConfirmPasswordLabel,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            prefixIcon: Icons.lock_reset_rounded,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_isBusy) _signup();
                            },
                            suffix: PasswordVisibilityButton(
                              obscured: _obscureConfirm,
                              showLabel: loc.loginShowPassword,
                              hideLabel: loc.loginHidePassword,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return loc.signupPasswordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          AuthErrorBanner(message: _errorMessage),
                          PrimaryButton(
                            label: _isLoading
                                ? loc.signupCreatingAccount
                                : loc.signupCreateAccountButton,
                            icon: Icons.arrow_forward_rounded,
                            isBusy: _isLoading,
                            onPressed: _isBusy ? null : _signup,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: Center(
                      child: TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                        child: Text(loc.signupAlreadyHaveAccount),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small icon badge + title that opens each group of fields.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: c.accentInk),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.plum,
                ),
          ),
        ),
      ],
    );
  }
}

/// Soft orchid note explaining the secret phrase.
class _HintNote extends StatelessWidget {
  const _HintNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.orchidSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: c.orchidInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c.orchidInk,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-segment strength bar under the password field.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;
    var points = 0;
    if (password.length >= 8) points++;
    if (password.length >= 12) points++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      points++;
    }
    if (RegExp(r'\d').hasMatch(password)) points++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) points++;
    if (password.length < 6 || points <= 1) return 1;
    if (points <= 3) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final loc = AppLocalizations.of(context);
    final score = _score;
    final (Color colour, String label) = switch (score) {
      1 => (c.terracotta, loc.signupStrengthWeak),
      2 => (c.gold, loc.signupStrengthFair),
      3 => (c.sage, loc.signupStrengthStrong),
      _ => (c.line, ''),
    };

    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: AmicaMotion.medium,
              curve: AmicaMotion.enter,
              height: 5,
              decoration: BoxDecoration(
                color: i <= score ? colour : c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
        const SizedBox(width: 10),
        SizedBox(
          width: 58,
          child: AnimatedSwitcher(
            duration: AmicaMotion.quick,
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colour,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
