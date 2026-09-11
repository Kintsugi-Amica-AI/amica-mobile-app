import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
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
      setState(() => _errorMessage = 'Signup failed. Please try again.');
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
        () => _errorMessage = 'Google sign-in failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Create account')),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Join Amica',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your profile for safety alerts and trusted contacts.',
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) => _required(value, 'Name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Phone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.call_outlined,
                        validator: (value) => _required(value, 'Phone'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Secret phrase',
                        controller: _secretPhraseController,
                        prefixIcon: Icons.record_voice_over_outlined,
                        helperText: 'Say this during a fake call to trigger stealth SOS.',
                        validator: (value) => _required(value, 'Secret phrase'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
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
                        label:
                            _isLoading ? 'Creating account...' : 'Create account',
                        icon: Icons.person_add_alt_1_rounded,
                        onPressed: _isBusy ? null : _signup,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isBusy ? null : _continueWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded),
                        label: Text(
                          _isGoogleLoading
                              ? 'Connecting...'
                              : 'Continue with Google',
                        ),
                      ),
                      TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                  context,
                                  AppRoutes.login,
                                ),
                        child: const Text('Already have an account? Log in'),
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
