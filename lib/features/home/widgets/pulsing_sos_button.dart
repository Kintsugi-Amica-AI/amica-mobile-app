import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// The hero SOS action on the Home Dashboard: a large circular button with
/// an animated glowing pulse ring, so it reads instantly as "the panic
/// button" in a stressful moment.
class PulsingSosButton extends StatefulWidget {
  const PulsingSosButton({
    required this.onTap,
    super.key,
    this.isBusy = false,
    this.label = 'SOS',
  });

  final VoidCallback onTap;
  final bool isBusy;
  final String label;

  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.isBusy ? null : widget.onTap,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = _controller.value;
              return SizedBox(
                width: 176,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ringAt(pulse),
                    _ringAt((pulse + 0.5) % 1.0),
                    child!,
                  ],
                ),
              );
            },
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.sosGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alert.withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: widget.isBusy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sos_rounded,
                              color: Colors.white, size: 38),
                          const SizedBox(height: 4),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.isBusy ? 'Sending your live alert...' : 'Tap for instant SOS',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _ringAt(double t) {
    final size = 128 + t * 48;
    final opacity = (1 - t).clamp(0.0, 1.0) * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.alert.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}
