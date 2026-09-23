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

/// Keeps every tab alive (like IndexedStack) but cross-fades between them
/// instead of cutting. Hidden tabs stop ticking, are
/// not painted, and are hidden from screen readers and taps.
class AnimatedTabStack extends StatelessWidget {
  const AnimatedTabStack({
    required this.index,
    required this.children,
    super.key,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduced = AmicaMotion.reduced(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _Tab(
            key: ValueKey(i),
            active: i == index,
            reduced: reduced,
            child: children[i],
          ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.active,
    required this.reduced,
    required this.child,
    super.key,
  });

  final bool active;
  final bool reduced;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration =
        reduced ? Duration.zero : const Duration(milliseconds: 220);
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: TickerMode(
          enabled: active,
          // Fade only: sliding a tab that holds a live map (a platform
          // view) is expensive and made tab switches stutter.
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: duration,
            curve: active ? AmicaMotion.enter : AmicaMotion.exit,
            child: RepaintBoundary(child: child),
          ),
        ),
      ),
    );
  }
}
