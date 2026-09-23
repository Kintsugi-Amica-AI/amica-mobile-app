import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.authService = const AuthService(),
  });

  final AuthService authService;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.authService.sendPasswordReset(_emailController.text);

      if (!mounted) {
        return;
      }

      setState(() {
        _successMessage = AppLocalizations.of(context)!.forgotPasswordSuccess;
      });
    } on AuthServiceException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (_) {
      setState(
        () => _errorMessage = AppLocalizations.of(context)!.forgotPasswordFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(loc.forgotPasswordAppBarTitle)),
      extendBodyBehindAppBar: true,
      body: AmicaBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Icon(Icons.lock_reset_rounded,
                    color: Theme.of(context).amica.sage, size: 48),
                const SizedBox(height: 16),
                Text(
                  loc.forgotPasswordHeading,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(loc.forgotPasswordSubtitle),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        label: loc.commonEmail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.alternate_email_rounded,
                        validator: (value) {
                          if (value == null || !value.trim().contains('@')) {
                            return loc.forgotPasswordEmailInvalid;
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
                      if (_successMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _successMessage!,
                          style: TextStyle(color: Theme.of(context).amica.sage),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: _isLoading
                            ? loc.forgotPasswordSending
                            : loc.forgotPasswordSendButton,
                        icon: Icons.mail_outline_rounded,
                        onPressed: _isLoading ? null : _sendResetLink,
                      ),
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        child: Text(loc.forgotPasswordBackToLogin),
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
