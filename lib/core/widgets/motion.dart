import 'package:flutter/material.dart';

/// Amica's motion vocabulary: one set of durations and curves so every
/// transition in the app feels like it belongs to the same thing.
///
/// Everything here respects the system "remove animations" setting
/// (`MediaQuery.disableAnimations`), which some people need.
class AmicaMotion {
  const AmicaMotion._();

  static const Duration quick = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);

  /// Settles gently — for things arriving.
  static const Curve enter = Curves.easeOutCubic;

  /// Leaves promptly — for things going away.
  static const Curve exit = Curves.easeInCubic;

  /// A small, springy overshoot — for selection "pops".
  static const Curve pop = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Fades and rises a child into place once, when it first appears.
/// Use [delay] to stagger a column of sections.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = AmicaMotion.slow,
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting offset, as a fraction of the child's size.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AmicaMotion.enter,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AmicaMotion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Shrinks its child slightly while a finger is on it, then springs back —
/// the tactile "press" that makes tiles and buttons feel physical.
/// Purely visual: taps still go to the child's own InkWell / GestureDetector.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    super.key,
    this.scale = 0.96,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AmicaMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? AmicaMotion.quick : AmicaMotion.medium,
        curve: _down ? Curves.easeOut : AmicaMotion.pop,
        child: widget.child,
      ),
    );
  }
}

/// Keeps every tab alive (it *is* an IndexedStack underneath) and fades
/// the newly selected tab in.
///
/// Only the selected tab is ever painted. An earlier version stacked all
/// tabs and faded their opacity, but a live Google Map is a platform view,
/// which ignores opacity — so the Journeys map showed through on top of
/// the other tabs.
class AnimatedTabStack extends StatefulWidget {
  const AnimatedTabStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  State<AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<AnimatedTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _fade,
    curve: AmicaMotion.enter,
  );

  @override
  void didUpdateWidget(AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (AmicaMotion.reduced(context)) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: [
          for (var i = 0; i < widget.children.length; i++)
            TickerMode(
              enabled: i == widget.index,
              child: widget.children[i],
            ),
        ],
      ),
    );
  }
}
