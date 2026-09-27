import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/services/phone_verification_service.dart';

/// Opens the two-step SMS verification sheet. Resolves to true once the
/// number is verified, linked to the account and saved to the profile.
///
/// While [FeatureFlags.phoneSmsVerification] is off, the sheet is a single
/// step: enter the number and save it unverified.
Future<bool> showPhoneVerificationSheet(
  BuildContext context, {
  String initialPhone = '',
  PhoneVerificationService service = const PhoneVerificationService(),
}) async {
  final verified = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PhoneVerificationSheet(
      initialPhone: initialPhone,
      service: service,
    ),
  );
  return verified == true;
}

/// Step 1: enter the number, "Send code". Step 2: enter the 6-digit SMS
/// code, "Verify" (with a resend countdown). On Android the code is often
/// read automatically and the sheet closes by itself.
class PhoneVerificationSheet extends StatefulWidget {
  const PhoneVerificationSheet({
    required this.initialPhone,
    required this.service,
    super.key,
  });

  final String initialPhone;
  final PhoneVerificationService service;

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  static const int _resendSeconds = 30;

  late final _phone = TextEditingController(text: widget.initialPhone);
  final _code = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();

  String? _verificationId;
  int? _resendToken;
  String? _e164;
  bool _busy = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _ticker;

  bool get _codeStep => _verificationId != null;

  @override
  void dispose() {
    _ticker?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !_phoneFormKey.currentState!.validate()) return;
    final e164 = resend ? _e164! : PhoneVerificationService.normalize(_phone.text)!;
    setState(() {
      _busy = true;
      _error = null;
      _e164 = e164;
    });
    try {
      await widget.service.sendCode(
        phoneE164: e164,
        resendToken: resend ? _resendToken : null,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _startResendCountdown();
        },
        onAutoVerified: () {
          if (mounted) Navigator.pop(context, true);
        },
        onFailed: _fail,
      );
    } catch (_) {
      _fail(const PhoneVerificationException(PhoneVerificationError.unknown));
    }
  }

  /// SMS verification off: save the number as-is, unverified.
  Future<void> _saveWithoutCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final e164 = PhoneVerificationService.normalize(_phone.text)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.saveUnverified(e164);
      if (mounted) Navigator.pop(context, true);
    } on PhoneVerificationException catch (error) {
      _fail(error);
    } catch (_) {
      _fail(const PhoneVerificationException(PhoneVerificationError.unknown));
    }
  }

  Future<void> _confirm() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = AppLocalizations.of(context).phoneErrInvalidCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.confirmCode(
        verificationId: _verificationId!,
        smsCode: code,
        phoneE164: _e164!,
      );
      if (mounted) Navigator.pop(context, true);
    } on PhoneVerificationException catch (error) {
      _fail(error);
    } catch (_) {
      _fail(const PhoneVerificationException(PhoneVerificationError.unknown));
    }
  }

  void _fail(PhoneVerificationException error) {
    if (!mounted) return;
    debugPrint('Phone verification failed: $error');
    setState(() {
      _busy = false;
      _error = _messageFor(AppLocalizations.of(context), error);
    });
  }

  static String _messageFor(
    AppLocalizations loc,
    PhoneVerificationException error,
  ) {
    return switch (error.error) {
      PhoneVerificationError.invalidNumber => loc.phoneInvalidNumber,
      PhoneVerificationError.invalidCode => loc.phoneErrInvalidCode,
      PhoneVerificationError.expired => loc.phoneErrExpired,
      PhoneVerificationError.tooManyRequests => loc.phoneErrTooMany,
      PhoneVerificationError.alreadyInUse => loc.phoneErrInUse,
      PhoneVerificationError.notEnabled => loc.phoneErrNotEnabled,
      PhoneVerificationError.appNotAuthorized => loc.phoneErrAppNotAuthorized,
      PhoneVerificationError.saveFailed =>
        loc.profileSaveFailedWithCode(error.code ?? 'unknown'),
      PhoneVerificationError.network ||
      PhoneVerificationError.notSignedIn ||
      PhoneVerificationError.unknown =>
        loc.phoneErrGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = theme.amica;
    const smsOn = FeatureFlags.phoneSmsVerification;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: c.accentGradient,
                    boxShadow: c.accentGlow,
                  ),
                  child: Icon(
                    _codeStep ? Icons.sms_outlined : Icons.phone_iphone_rounded,
                    color: AppColors.onAccent,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                smsOn ? loc.phoneVerifyTitle : loc.phoneAddTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                _codeStep
                    ? loc.phoneCodeSentTo(_e164!)
                    : smsOn
                        ? loc.phoneVerifySubtitle
                        : loc.phoneAddSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              if (!_codeStep)
                Form(
                  key: _phoneFormKey,
                  child: TextFormField(
                    controller: _phone,
                    enabled: !_busy,
                    autofocus: widget.initialPhone.isEmpty,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: InputDecoration(
                      labelText: loc.profilePhoneLabel,
                      hintText: '+94 77 123 4567',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) =>
                        PhoneVerificationService.normalize(v ?? '') == null
                            ? loc.phoneInvalidNumber
                            : null,
                    onFieldSubmitted: (_) => _busy
                        ? null
                        : smsOn
                            ? _sendCode()
                            : _saveWithoutCode(),
                  ),
                )
              else ...[
                TextField(
                  controller: _code,
                  enabled: !_busy,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.phoneCodeLabel,
                    counterText: '',
                  ),
                  onChanged: (value) {
                    if (value.length == 6 && !_busy) _confirm();
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _verificationId = null;
                                _code.clear();
                                _error = null;
                                _ticker?.cancel();
                                _secondsLeft = 0;
                              }),
                      child: Text(loc.phoneChangeNumber),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _busy || _secondsLeft > 0
                          ? null
                          : () => _sendCode(resend: true),
                      child: Text(
                        _secondsLeft > 0
                            ? loc.phoneResendIn(_secondsLeft)
                            : loc.phoneResend,
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.blush,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 18, color: c.terracottaDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: c.terracottaDeep,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (smsOn)
                PrimaryButton(
                  label: _codeStep ? loc.phoneVerifyButton : loc.phoneSendCode,
                  icon: _codeStep ? Icons.verified_rounded : Icons.send_rounded,
                  isBusy: _busy,
                  onPressed: _codeStep ? _confirm : () => _sendCode(),
                )
              else
                PrimaryButton(
                  label: loc.commonSave,
                  icon: Icons.check_rounded,
                  isBusy: _busy,
                  onPressed: _saveWithoutCode,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
