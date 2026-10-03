import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// One-shot particle burst animation shown on conversion success.
///
/// 18 particles radiate outward in random directions with orange and teal
/// colors, fading and moving away from the centre.
///
/// - [active]: flipping this from false → true fires the burst.
/// - [child]: the widget the burst is centred on.
///
/// Respects `MediaQuery.disableAnimations`: when true the particles are
/// skipped and [child] is rendered immediately.
class Burst extends StatefulWidget {
  const Burst({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<Burst> createState() => _BurstState();
}

class _BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _fired = false;

  static const int _count = 18;
  static const double _maxRadius = 80;

  // Pre-generate stable particle configs
  final List<_Particle> _particles = List.generate(_count, (i) {
    final rng = math.Random(i * 17 + 3);
    final angle = (i / _count) * math.pi * 2 + rng.nextDouble() * 0.4;
    final speed = 0.5 + rng.nextDouble() * 0.5;
    final size = 4.0 + rng.nextDouble() * 5.0;
    final useOrange = rng.nextBool();
    return _Particle(
      angle: angle,
      speed: speed,
      size: size,
      useOrange: useOrange,
    );
  });

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Motion.long,
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _fired = false);
      }
    });
    if (widget.active) _fire();
  }

  @override
  void didUpdateWidget(Burst old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _fire();
  }

  void _fire() {
    if (Motion.reduced(context)) return;
    setState(() => _fired = true);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.peel;

    if (!_fired) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => CustomPaint(
        foregroundPainter: _BurstPainter(
          t: _ctrl.value,
          particles: _particles,
          peelColor: c.peel,
          grooveColor: c.groove,
          maxRadius: _maxRadius,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ─── Data ──────────────────────────────────────────────────────────────────────

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.useOrange,
  });

  final double angle;
  final double speed;
  final double size;
  final bool useOrange;
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.t,
    required this.particles,
    required this.peelColor,
    required this.grooveColor,
    required this.maxRadius,
  });

  final double t;
  final List<_Particle> particles;
  final Color peelColor;
  final Color grooveColor;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    // Ease: fast out then decelerate
    final ease = Curves.easeOutCubic.transform(t);
    // Fade: full opacity until 70% then fade
    final fade = (1 - ((t - 0.7) / 0.3).clamp(0.0, 1.0));

    for (final p in particles) {
      final r = maxRadius * ease * p.speed;
      final dx = math.cos(p.angle) * r;
      final dy = math.sin(p.angle) * r;
      final pos = centre + Offset(dx, dy);

      // Shrink particle size as it travels
      final currentSize = p.size * (1 - ease * 0.5);

      final color = (p.useOrange ? peelColor : grooveColor)
          .withValues(alpha: fade * 0.9);

      canvas.drawCircle(pos, currentSize / 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
