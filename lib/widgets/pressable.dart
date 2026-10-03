import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../design/motion.dart';

/// Wraps [child] with a press-scale spring animation.
///
/// Scales to 0.96 on press and springs back to 1.0 on release.
/// Fires [Haptics.tap] on press-down and triggers [onTap] on release.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const double _pressedScale = 0.96;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // Allow the spring to overshoot slightly above 1.0
      upperBound: 1.05,
      lowerBound: 0.0,
      value: 1.0,
      duration: Motion.short,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    Haptics.tap();
    _springTo(_pressedScale);
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.enabled) return;
    _springTo(1.0);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    _springTo(1.0);
  }

  void _springTo(double target) {
    final sim = SpringSimulation(
      Motion.pressSpring,
      _ctrl.value,
      target,
      0.0,
    );
    _ctrl.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = widget.enabled && widget.onTap != null;

    return GestureDetector(
      onTapDown: effectiveEnabled ? _onTapDown : null,
      onTapUp: effectiveEnabled ? _onTapUp : null,
      onTapCancel: effectiveEnabled ? _onTapCancel : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _ctrl.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
