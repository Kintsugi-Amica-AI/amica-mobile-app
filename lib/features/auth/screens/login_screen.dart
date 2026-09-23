import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_logo.dart';
import '../../../core/widgets/custom_text_field.dart';
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
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    // No card around the form. On the old screen the fields sat inside a
    // translucent panel floating on a gradient, which made the first thing
    // a new user saw look like a pop-up rather than the app.
    return Scaffold(
      backgroundColor: c.ivory,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            children: [
              const SizedBox(height: 12),
              const AmicaLogo(),
              const SizedBox(height: 36),
              Text(loc.loginWelcomeBack, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                loc.loginSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 26),
              CustomTextField(
                label: loc.commonEmail,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return loc.commonEnterValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: loc.commonPassword,
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isBusy ? null : _login(),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: c.blush,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 17, color: c.terracottaDeep),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: c.terracottaDeep,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: loc.loginButton,
                isBusy: _isLoading,
                onPressed: _isBusy ? null : _login,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: loc.continueWithGoogle,
                tone: AmicaButtonTone.quiet,
                isBusy: _isGoogleLoading,
                onPressed: _isBusy ? null : _continueWithGoogle,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(loc.loginNewToAmica, style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.pushNamed(context, AppRoutes.signup),
                    child: Text(loc.loginCreateAccount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
