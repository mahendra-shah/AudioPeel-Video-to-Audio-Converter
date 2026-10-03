import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// Animates between numeric values with a vertical roll effect.
///
/// On value change the old value rolls up and the new value rolls in from
/// below, giving a slot-machine feel. Uses [AnimatedSwitcher] with a
/// custom vertical slide + fade transition.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  final num value;
  final String Function(num) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label = format(value);

    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.short),
      switchInCurve: Motion.emphasizedDecel,
      switchOutCurve: Motion.emphasizedAccel,
      transitionBuilder: (child, animation) {
        // New value slides in from below; old value slides out to the top.
        final isNew = child.key == ValueKey(label);
        final beginOffset =
            isNew ? const Offset(0, 1) : const Offset(0, -1);
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        label,
        key: ValueKey(label),
        style: style ??
            monoStyle(context, size: 13, color: context.peel.inkMuted),
      ),
    );
  }
}
