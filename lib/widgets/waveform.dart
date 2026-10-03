import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// An animated equalizer waveform with 32 vertical bars.
///
/// - When [playing] is true the bars animate at random heights.
/// - When [playing] is false all bars sit at 30 % height.
/// - [color] overrides the bar colour (defaults to [PeelColors.peel]).
class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    required this.playing,
    this.color,
  });

  final bool playing;
  final Color? color;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const int _barCount = 32;

  // Each bar has an independent phase offset so they don't all move together.
  final List<double> _phases = List.generate(
    _barCount,
    (i) => (i * 0.37 + math.Random(i).nextDouble()) % (math.pi * 2),
  );

  // Pseudo-random amplitude 0.3–1.0 per bar
  final List<double> _amps = List.generate(
    _barCount,
    (i) => 0.3 + math.Random(i * 7 + 3).nextDouble() * 0.7,
  );

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.playing && !Motion.reduced(context)) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(Waveform old) {
    super.didUpdateWidget(old);
    if (widget.playing != old.playing) {
      if (widget.playing && !Motion.reduced(context)) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final color = widget.color ?? c.peel;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * math.pi * 2;
        return CustomPaint(
          painter: _WaveformPainter(
            t: widget.playing ? t : 0,
            phases: _phases,
            amps: _amps,
            color: color,
            playing: widget.playing,
            barCount: _barCount,
          ),
        );
      },
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.t,
    required this.phases,
    required this.amps,
    required this.color,
    required this.playing,
    required this.barCount,
  });

  final double t;
  final List<double> phases;
  final List<double> amps;
  final Color color;
  final bool playing;
  final int barCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final spacing = size.width / barCount;
    final barWidth = spacing * 0.65;

    for (int i = 0; i < barCount; i++) {
      double heightFraction;
      if (!playing) {
        heightFraction = 0.30;
      } else {
        // Sine wave with individual phase — result clamped to 0.15–1.0
        final raw = (math.sin(t + phases[i]) * 0.5 + 0.5) * amps[i];
        heightFraction = raw.clamp(0.15, 1.0);
      }

      final barH = size.height * heightFraction;
      final x = i * spacing + (spacing - barWidth) / 2;
      final y = (size.height - barH) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barH),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.t != t || old.playing != playing || old.color != color;
}
