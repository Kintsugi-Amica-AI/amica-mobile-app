import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/amica_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';

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
    final destinationName = widget.arguments?.destinationName ?? 'your trip';

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
                  'Are you safe?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your journey timer for $destinationName has ended.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildEscalationCard(context),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'I am safe',
                  icon: Icons.verified_user_rounded,
                  onPressed: () => _answer(SafetyCheckResult.safe),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Send SOS now',
                  icon: Icons.sos_rounded,
                  isDanger: true,
                  onPressed: () => _answer(SafetyCheckResult.sos),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tapping "I am safe" closes this journey. Amica will stop '
                  'watching and will not contact anyone.',
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

  Widget _buildPulsingShield() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glow = 24 + (_pulseController.value * 22);
        return Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.auraGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: glow,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const Icon(
        Icons.shield_moon_rounded,
        color: Colors.white,
        size: 54,
      ),
    );
  }

  Widget _buildEscalationCard(BuildContext context) {
    if (widget.arguments?.escalationAt == null) {
      return GlassCard(
        borderColor: AppColors.warning,
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Answer so Amica knows whether to alert your emergency '
                'contact.',
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
        final color = hasEscalated ? AppColors.alert : AppColors.warning;

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
                    ? 'Amica has alerted your emergency contact'
                    : 'Auto-alert in',
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
                  'If you do not answer, Amica messages your primary '
                  'emergency contact with your live location, then calls them.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  'You can still confirm you are safe, or escalate to a full '
                  'SOS with your live location.',
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
