import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../l10n/generated/app_localizations.dart';

/// What the user decided when the journey timer ran out.
///
/// Returned through `Navigator.pop` so the journey timer screen — which owns
/// the journey document, the native safety monitor, and the escalation
/// timers — stays the single place that performs the side effects.
enum SafetyCheckResult {
  safe,
  sos,
}

class SafetyCheckArguments {
  const SafetyCheckArguments({
    required this.destinationName,
    this.journeyId,
    this.escalationAt,
  });

  final String destinationName;
  final String? journeyId;

  /// When Amica automatically messages the primary emergency contact if the
  /// user has still not responded. Used to show an honest countdown.
  final DateTime? escalationAt;
}

/// Full-screen "are you safe?" prompt shown when a journey timer expires.
///
/// This is deliberately not dismissible with the back button: an accidental
/// swipe should never look like a safety confirmation. The only ways out are
/// the two explicit answers, both of which pop a [SafetyCheckResult].
class SafetyCheckScreen extends StatefulWidget {
  const SafetyCheckScreen({
    super.key,
    this.arguments,
  });

  final SafetyCheckArguments? arguments;

  @override
  State<SafetyCheckScreen> createState() => _SafetyCheckScreenState();
}

class _SafetyCheckScreenState extends State<SafetyCheckScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Duration?> _untilEscalationNotifier =
      ValueNotifier<Duration?>(null);

  late final AnimationController _pulseController;
  Timer? _countdownTimer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _updateEscalationCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateEscalationCountdown(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _untilEscalationNotifier.dispose();
    super.dispose();
  }

  void _updateEscalationCountdown() {
    final escalationAt = widget.arguments?.escalationAt;
    if (escalationAt == null) {
      return;
    }

    final remaining = escalationAt.difference(DateTime.now());
    _untilEscalationNotifier.value =
        remaining.isNegative ? Duration.zero : remaining;
  }

  void _answer(SafetyCheckResult result) {
    if (_isAnswered) {
      return;
    }
    _isAnswered = true;
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final destinationName =
        widget.arguments?.destinationName ?? loc.safetyCheckDefaultTrip;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AmicaBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Center(child: _buildPulsingShield()),
                const SizedBox(height: 24),
                Text(
                  loc.safetyCheckAreYouSafe,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.safetyCheckTimerEnded(destinationName),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildEscalationCard(context),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: loc.safetyCheckImSafe,
                  icon: Icons.verified_user_rounded,
                  onPressed: () => _answer(SafetyCheckResult.safe),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: loc.safetyCheckSendSosNow,
                  icon: Icons.sos_rounded,
                  isDanger: true,
                  onPressed: () => _answer(SafetyCheckResult.sos),
                ),
                const SizedBox(height: 20),
                Text(
                  loc.safetyCheckSafeClosesNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A slow breath rather than a throb: this screen appears when a journey
  /// timer is running out, and an urgently pulsing glow makes an already
  /// anxious moment worse.
  Widget _buildPulsingShield() {
    final c = Theme.of(context).amica;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final halo = 108 + (_pulseController.value * 14);
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: halo,
                height: halo,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.blush.withValues(alpha: 0.55),
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.blush,
                ),
                child: child,
              ),
            ],
          ),
        );
      },
      child: Icon(
        Icons.shield_outlined,
        color: c.terracottaDeep,
        size: 46,
      ),
    );
  }

  Widget _buildEscalationCard(BuildContext context) {
    if (widget.arguments?.escalationAt == null) {
      return GlassCard(
        borderColor: Theme.of(context).amica.gold,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).amica.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).safetyCheckAnswerPrompt,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<Duration?>(
      valueListenable: _untilEscalationNotifier,
      builder: (context, remaining, _) {
        final hasEscalated = remaining == null || remaining == Duration.zero;
        final color = hasEscalated ? Theme.of(context).amica.terracotta : Theme.of(context).amica.gold;

        return GlassCard(
          borderColor: color,
          child: Column(
            children: [
              Icon(
                hasEscalated
                    ? Icons.campaign_rounded
                    : Icons.hourglass_bottom_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                hasEscalated
                    ? AppLocalizations.of(context).safetyCheckContactAlerted
                    : AppLocalizations.of(context).safetyCheckAutoAlertIn,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.2,
                    ),
              ),
              if (!hasEscalated) ...[
                const SizedBox(height: 6),
                Text(
                  DateTimeUtils.formatDuration(remaining),
                  style: TextStyle(
                    color: color,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).safetyCheckEscalationExplain,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context).safetyCheckAfterEscalationNote,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
