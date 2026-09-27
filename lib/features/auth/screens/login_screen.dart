import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_logo.dart';
import '../../../core/widgets/auth_widgets.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authService = const AuthService(),
  });

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = AppLocalizations.of(context).loginFailed,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    // Logo on the pastel ground, then one frosted card holding the whole
    // sign-in — email, password, log in, or Google — and the sign-up link
    // underneath. Sections drift in one after another.
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              children: [
                const SizedBox(height: 8),
                const FadeSlideIn(
                  offset: Offset(0, 0.08),
                  child: Center(child: AmicaLogo(size: 116)),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: AmicaCard(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    borderRadius: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loc.loginWelcomeBack,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 22),
                        CustomTextField(
                          label: loc.commonEmail,
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return loc.commonEnterValidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: loc.commonPassword,
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _isBusy ? null : _login(),
                          suffix: PasswordVisibilityButton(
                            obscured: _obscurePassword,
                            showLabel: loc.loginShowPassword,
                            hideLabel: loc.loginHidePassword,
                            onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.loginPasswordRequired;
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isBusy
                                ? null
                                : () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.forgotPassword,
                                    ),
                            child: Text(loc.loginForgotPassword),
                          ),
                        ),
                        AuthErrorBanner(message: _errorMessage),
                        PrimaryButton(
                          label: loc.loginButton,
                          icon: Icons.arrow_forward_rounded,
                          isBusy: _isLoading,
                          onPressed: _isBusy ? null : _login,
                        ),
                        const SizedBox(height: 18),
                        OrDivider(label: loc.loginOr),
                        const SizedBox(height: 18),
                        GoogleSignInButton(
                          label: loc.continueWithGoogle,
                          isBusy: _isGoogleLoading,
                          onPressed: _isBusy ? null : _continueWithGoogle,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.loginNewToAmica,
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () =>
                                Navigator.pushNamed(context, AppRoutes.signup),
                        child: Text(loc.loginCreateAccount),
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
