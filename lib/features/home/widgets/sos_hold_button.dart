import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The hero SOS control: **hold** to send, not tap.
///
/// The previous button fired on a single tap. That is the wrong trade for
/// this app in both directions — it goes off in a pocket or a handbag, and
/// a false alert that pulls three people out of bed (or reaches emergency
/// services) teaches a woman not to trust the button she may one day
/// actually need. A deliberate hold costs two seconds and removes that
/// whole class of mistake.
///
/// The hold is legible while it happens: a ring fills, a countdown reads
/// down, and the label says how to back out. Releasing early cancels with
/// nothing sent.
class SosHoldButton extends StatefulWidget {
  const SosHoldButton({
    required this.onTriggered,
    super.key,
    this.isBusy = false,
    this.holdDuration = const Duration(milliseconds: 2000),
  });

  /// Fires once, when the hold completes.
  final VoidCallback onTriggered;

  /// Swaps the face for a spinner while the alert is being created.
  final bool isBusy;

  /// How long the hold must be sustained. Two seconds is the balance point:
  /// long enough that it cannot happen by accident in a bag, short enough
  /// to be bearable when you are frightened.
  final Duration holdDuration;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton>
    with SingleTickerProviderStateMixin {
  static const double _outer = 186;
  static const double _core = 150;
  static const double _ringWidth = 6;

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  );

  bool _fired = false;
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    _hold
      ..addStatusListener(_onStatus)
      ..addListener(_onTick);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      widget.onTriggered();
    }
  }

  /// A pulse each second so the hold is felt as well as seen — the phone may
  /// well be out of sight, in a pocket or held down by the side.
  void _onTick() {
    final remaining = _remainingSeconds;
    if (remaining != _lastTickSecond) {
      _lastTickSecond = remaining;
      if (_hold.isAnimating) HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  int get _remainingSeconds {
    final ms = widget.holdDuration.inMilliseconds * (1 - _hold.value);
    return (ms / 1000).ceil();
  }

  void _start() {
    if (widget.isBusy) return;
    _fired = false;
    HapticFeedback.mediumImpact();
    _hold.forward(from: 0);
  }

  /// Cancels a hold in progress. Reverses rather than snapping to zero so a
  /// near-miss reads as "that didn't send" instead of the ring vanishing.
  void _cancel() {
    if (_fired || !mounted) return;
    _hold.reverse();
  }

  @override
  void dispose() {
    _hold
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).amica;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final holding = _hold.value > 0 && !_fired;

    return Semantics(
      button: true,
      label: loc.sosHoldSemanticLabel,
      hint: loc.sosHoldSemanticHint,
      onTap: widget.onTriggered,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTapDown: (_) => _start(),
            onTapUp: (_) => _cancel(),
            onTapCancel: _cancel,
            child: SizedBox(
              width: _outer,
              height: _outer,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo. Static — it marks the target, it does not pulse.
                  // A perpetually throbbing button is exhausting to live
                  // beside on a home screen you open every day.
                  Container(
                    width: _outer,
                    height: _outer,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.blush,
                    ),
                  ),
                  Container(
                    width: _core,
                    height: _core,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.terracotta,
                      boxShadow: c.lift,
                    ),
                    child: Center(
                      child: widget.isBusy
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.onTerracotta,
                                ),
                              ),
                            )
                          : holding
                              ? Text(
                                  '${_remainingSeconds}s',
                                  style: theme.textTheme.displaySmall
                                      ?.copyWith(
                                    color: AppColors.onTerracotta,
                                    fontSize: 38,
                                    height: 1,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.onTerracotta,
                                      size: 34,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      loc.sosHoldLabel,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        color: AppColors.onTerracotta,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                  if (holding)
                    SizedBox(
                      width: _core + 18,
                      height: _core + 18,
                      child: CustomPaint(
                        painter: _HoldRingPainter(
                          progress: _hold.value,
                          color: AppColors.onTerracotta,
                          strokeWidth: _ringWidth,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.isBusy
                ? loc.sosHoldReachingCircle
                : holding
                    ? loc.sosHoldKeepHolding
                    : loc.sosHoldToSend,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: holding ? c.terracottaDeep : c.plum70,
              fontWeight: holding ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = rect.center;

    final track = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) =>
      old.progress != progress || old.color != color;
}
