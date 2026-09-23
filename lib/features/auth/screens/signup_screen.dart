import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(loc.signupAppBarTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  loc.signupJoinAmica,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(loc.signupSubtitle),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: loc.signupNameLabel,
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) => _required(value, loc.signupNameLabel),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.commonEmail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return loc.signupEmailInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.signupPhoneLabel,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.call_outlined,
                        validator: (value) => _required(value, loc.signupPhoneLabel),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.signupSecretPhraseLabel,
                        controller: _secretPhraseController,
                        prefixIcon: Icons.record_voice_over_outlined,
                        helperText: loc.signupSecretPhraseHelper,
                        validator: (value) =>
                            _required(value, loc.signupSecretPhraseLabel),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.commonPassword,
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return loc.signupPasswordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: loc.signupConfirmPasswordLabel,
                        controller: _confirmPasswordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return loc.signupPasswordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isLoading
                            ? loc.signupCreatingAccount
                            : loc.signupCreateAccountButton,
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: _isBusy ? null : _signup,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _continueWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: Text(
                          _isGoogleLoading ? loc.connecting : loc.continueWithGoogle,
                        ),
                      ),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                        child: Text(loc.signupAlreadyHaveAccount),
                      ),
                    ],
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
