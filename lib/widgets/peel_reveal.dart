import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/motion.dart';

/// Animated conversion progress "peel" visualization.
///
/// A video thumbnail is progressively clipped from left to right, revealing
/// a peel + groove gradient underneath. At the reveal seam a glowing vertical
/// line pulses in the peel color.
///
/// - [progress]: 0.0 – 1.0 controls how much has been revealed.
/// - [thumbnail]: raw image bytes (JPEG/PNG). A gradient placeholder is shown
///   when null.
/// - [height]: total widget height (defaults to 200).
class PeelReveal extends StatefulWidget {
  const PeelReveal({
    super.key,
    required this.progress,
    this.thumbnail,
    this.height = 200,
  });

  final double progress;
  final Uint8List? thumbnail;
  final double height;

  @override
  State<PeelReveal> createState() => _PeelRevealState();
}

class _PeelRevealState extends State<PeelReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final p = widget.progress.clamp(0.0, 1.0);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Revealed gradient layer (left side) ─────────────────
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => CustomPaint(
                painter: _RevealPainter(
                  progress: p,
                  glowPulse: _glowCtrl.value,
                  peelColor: c.peel,
                  grooveColor: c.groove,
                ),
              ),
            ),

            // ── Thumbnail (right/unrevealed portion) ─────────────────
            if (widget.thumbnail != null)
              ClipRect(
                clipper: _RightClipper(p),
                child: Image.memory(
                  widget.thumbnail!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            else
              // Placeholder when no thumbnail
              ClipRect(
                clipper: _RightClipper(p),
                child: ColoredBox(color: c.surfaceHi),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _RevealPainter extends CustomPainter {
  const _RevealPainter({
    required this.progress,
    required this.glowPulse,
    required this.peelColor,
    required this.grooveColor,
  });

  final double progress;
  final double glowPulse;
  final Color peelColor;
  final Color grooveColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final revealX = size.width * progress;
    final revealRect = Rect.fromLTWH(0, 0, revealX, size.height);

    // Background gradient
    canvas.drawRect(
      revealRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            grooveColor.withValues(alpha: 0.9),
            peelColor.withValues(alpha: 0.8),
          ],
        ).createShader(revealRect),
    );

    // Simulated waveform bars inside revealed area
    _drawWaveform(canvas, size, revealX);

    // Glow seam at the edge
    if (progress < 1.0) {
      _drawGlow(canvas, size, revealX);
    }
  }

  void _drawWaveform(Canvas canvas, Size size, double revealX) {
    const barCount = 24;
    final spacing = revealX / barCount;
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final t = i / barCount;
      final h = size.height * (0.25 + 0.5 * _hash(t));
      final x = i * spacing + spacing * 0.15;
      final w = spacing * 0.7;
      final y = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), const Radius.circular(2)),
        barPaint,
      );
    }
  }

  void _drawGlow(Canvas canvas, Size size, double revealX) {
    final intensity = 0.55 + 0.45 * glowPulse;

    // Soft bloom
    canvas.drawLine(
      Offset(revealX, 0),
      Offset(revealX, size.height),
      Paint()
        ..color = peelColor.withValues(alpha: 0.6 * intensity)
        ..strokeWidth = 12
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * intensity),
    );

    // Hard edge line
    canvas.drawLine(
      Offset(revealX, 0),
      Offset(revealX, size.height),
      Paint()
        ..color = peelColor
        ..strokeWidth = 1.5,
    );
  }

  /// Deterministic pseudo-random 0..1 from a seed in [0, 1].
  double _hash(double t) {
    final v = (t * 123.45 + 67.89).abs();
    return v - v.floor();
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress || old.glowPulse != glowPulse;
}

// ─── Clip helpers ──────────────────────────────────────────────────────────────

class _RightClipper extends CustomClipper<Rect> {
  const _RightClipper(this.progress);
  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(size.width * progress, 0, size.width, size.height);

  @override
  bool shouldReclip(_RightClipper old) => old.progress != progress;
}
