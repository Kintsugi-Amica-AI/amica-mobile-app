import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../services/location_service.dart';
import '../../emergency_contacts/models/emergency_contact.dart';
import '../services/sos_audio_service.dart';
import '../services/sos_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'sos_active_screen.dart';

/// The five seconds between finishing the hold and actually alerting.
///
/// A safety app has two failure modes and they pull in opposite directions:
/// an alert that does not fire when she needs it, and an alert that fires
/// when she does not. The 2-second hold handles the second case for
/// pockets and handbags; this screen handles it for changes of mind —
/// she pressed, then the footsteps behind her turned out to be nothing.
///
/// It is deliberately loud: full-bleed terracotta, a counting number, and
/// a plain list of exactly what is about to happen. Nobody should be
/// surprised by what this button does.
class SosArmingScreen extends StatefulWidget {
  const SosArmingScreen({
    super.key,
    this.guardians = const [],
    this.countdown = const Duration(seconds: 5),
    this.sosService = const SosService(),
    this.locationService = const LocationService(),
  });

  final List<EmergencyContact> guardians;
  final Duration countdown;
  final SosService sosService;
  final LocationService locationService;

  @override
  State<SosArmingScreen> createState() => _SosArmingScreenState();
}

class _SosArmingScreenState extends State<SosArmingScreen> {
  static const Color _ground = AppColors.terracottaDeep;
  static const Color _ink = Color(0xFFFFF1F5);
  static const Color _inkDim = Color(0xFFFFD0DC);

  Timer? _ticker;
  late int _remaining = widget.countdown.inSeconds;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        _send();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _cancel() {
    _ticker?.cancel();
    HapticFeedback.selectionClick();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    // The clip starts now, while location and the alert are still being
    // worked out, so the first seconds are not lost.
    unawaited(SosAudioService.instance.startForSos(triggerType: 'manual'));

    try {
      final location = await widget.locationService.getCurrentLocationData();
      final alertId =
          await widget.sosService.createManualSosAlert(location: location);
      unawaited(SosAudioService.instance.attachAlert(alertId));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SosActiveScreen(
            arguments: SosActiveArguments(
              alertId: alertId,
              triggerType: 'manual',
              location: location,
            ),
          ),
        ),
      );
    } on LocationServiceException catch (error) {
      _fail(error.message);
    } on SosServiceException catch (error) {
      _fail(error.message);
    } catch (_) {
      if (!mounted) return;
      _fail(AppLocalizations.of(context).sosArmingSendFailed);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = message;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _guardianSentence(AppLocalizations loc) {
    final names = widget.guardians
        .where((g) => g.isActive)
        .map((g) => g.name.trim().split(RegExp(r'\s+')).first)
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.isEmpty) return loc.sosArmingGuardianNone;
    if (names.length == 1) return loc.sosArmingGuardianOne(names.first);
    if (names.length == 2) {
      return loc.sosArmingGuardianTwo(names.first, names.last);
    }
    final head = names.sublist(0, names.length - 1).join(', ');
    return loc.sosArmingGuardianMany(head, names.last);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    // Back-gesture must cancel, never silently send.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_sending) _cancel();
      },
      child: Scaffold(
        backgroundColor: _ground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  _sending
                      ? loc.sosArmingSendingLabel
                      : loc.sosArmingAlertingLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: _inkDim),
                ),
                const Spacer(),
                _Dial(
                  remaining: _remaining,
                  total: widget.countdown.inSeconds,
                  sending: _sending,
                ),
                const SizedBox(height: 26),
                Text(
                  _sending ? loc.sosArmingReachingNow : loc.sosArmingCancelIfMeant,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(color: _ink),
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 290),
                  child: Text(
                    _error ??
                        (_sending
                            ? loc.sosArmingStaySafe
                            : loc.sosArmingStopNow),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _error != null ? _ink : _inkDim,
                      fontSize: 14.5,
                      fontWeight:
                          _error != null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.sosArmingWhenZero,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: _inkDim),
                  ),
                ),
                const SizedBox(height: 11),
                _Consequence(
                  icon: Icons.location_on_outlined,
                  text: _guardianSentence(loc),
                ),
                const SizedBox(height: 9),
                _Consequence(
                  icon: Icons.mic_none_rounded,
                  text: loc.sosArmingRecordingAudio,
                ),
                const SizedBox(height: 9),
                _Consequence(
                  icon: Icons.phone_outlined,
                  text: loc.sosArmingCallReady,
                ),
                const SizedBox(height: 22),
                if (!_sending)
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: Material(
                      color: _ink,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _cancel,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.close_rounded,
                                  size: 19, color: _ground),
                              const SizedBox(width: 8),
                              Text(
                                loc.sosArmingCancelSendNothing,
                                style: const TextStyle(
                                  color: _ground,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_error != null)
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: Material(
                      color: _ink,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (_) => false,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Text(
                            loc.sosArmingBackToHome,
                            style: const TextStyle(
                              color: _ground,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({
    required this.remaining,
    required this.total,
    required this.sending,
  });

  final int remaining;
  final int total;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFFFF1F5);

    return SizedBox(
      width: 236,
      height: 236,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 236,
            height: 236,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: sending ? 0 : remaining / total),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: ink.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation(ink),
              ),
            ),
          ),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink.withValues(alpha: 0.10),
            ),
            child: Center(
              child: sending
                  ? const SizedBox(
                      width: 38,
                      height: 38,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        valueColor: AlwaysStoppedAnimation(ink),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 42, color: ink),
                        const SizedBox(height: 10),
                        Text(
                          '$remaining',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: ink,
                                fontSize: 46,
                                height: 1,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFFFF1F5);

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: ink.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: ink),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
