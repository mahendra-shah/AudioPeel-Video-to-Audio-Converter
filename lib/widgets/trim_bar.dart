import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/motion.dart';

/// A trim range selector showing a filmstrip of video frames with two
/// draggable handles for start/end trim points.
///
/// - [frames]: JPEG bytes for each filmstrip cell
/// - [durationMs]: total clip duration in milliseconds
/// - [startMs] / [endMs]: current trim window in milliseconds
/// - [onStartChanged] / [onEndChanged]: callbacks with new ms values
///
/// Also renders ±0.1 s nudge buttons beside each handle.
class TrimBar extends StatefulWidget {
  const TrimBar({
    super.key,
    required this.frames,
    required this.durationMs,
    required this.startMs,
    required this.endMs,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final List<Uint8List> frames;
  final int durationMs;
  final int startMs;
  final int endMs;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  State<TrimBar> createState() => _TrimBarState();
}

class _TrimBarState extends State<TrimBar> {
  static const double _handleW = 20.0;
  static const double _barH = 64.0;
  static const int _nudgeMs = 100; // 0.1 s

  double _filmW = 0;

  double _msToX(int ms) => (ms / widget.durationMs) * _filmW;

  int _xToMs(double x, {int minMs = 0, int? maxMs}) {
    final ms = (x / _filmW * widget.durationMs).round();
    return ms.clamp(minMs, maxMs ?? widget.durationMs);
  }

  String _fmt(int ms) {
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    final cs = (ms % 1000) ~/ 10;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${cs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.peel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── time labels ──────────────────────────────────────────────
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Space.xxs),
          child: Row(
            children: [
              Text(_fmt(widget.startMs),
                  style: monoStyle(context, size: 11, color: c.peel)),
              const Spacer(),
              Text(_fmt(widget.endMs),
                  style: monoStyle(context, size: 11, color: c.peel)),
            ],
          ),
        ),

        const SizedBox(height: Space.xxs),

        // ── filmstrip + handles ──────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          _filmW = math.max(1, constraints.maxWidth - _handleW);
          final startX = _msToX(widget.startMs);
          final endX = _msToX(widget.endMs);

          return SizedBox(
            height: _barH + 4,
            child: Stack(children: [
              // Filmstrip
              Positioned(
                left: _handleW / 2,
                right: _handleW / 2,
                top: 2,
                bottom: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.chip),
                  child: _Filmstrip(frames: widget.frames),
                ),
              ),

              // Left dark overlay (outside trim)
              if (startX > 0)
                Positioned(
                  left: _handleW / 2,
                  width: startX,
                  top: 2,
                  height: _barH,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Radii.chip),
                      bottomLeft: Radius.circular(Radii.chip),
                    ),
                    child:
                        ColoredBox(color: c.canvas.withValues(alpha: 0.65)),
                  ),
                ),

              // Right dark overlay (outside trim)
              if (endX < _filmW)
                Positioned(
                  left: _handleW / 2 + endX,
                  right: _handleW / 2,
                  top: 2,
                  height: _barH,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(Radii.chip),
                      bottomRight: Radius.circular(Radii.chip),
                    ),
                    child:
                        ColoredBox(color: c.canvas.withValues(alpha: 0.65)),
                  ),
                ),

              // Orange selection border overlay
              Positioned(
                left: _handleW / 2 + startX,
                width: math.max(0, endX - startX),
                top: 0,
                height: _barH + 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: c.peel, width: 2),
                    color: c.peel.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Left drag handle
              Positioned(
                left: startX,
                top: 0,
                bottom: 0,
                width: _handleW,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) {
                    final newX =
                        (startX + d.delta.dx).clamp(0, endX - 2);
                    widget.onStartChanged(
                        _xToMs(newX, minMs: 0, maxMs: widget.endMs - 200));
                  },
                  child: _Handle(color: c.peel, dir: _Dir.left),
                ),
              ),

              // Right drag handle
              Positioned(
                left: _handleW / 2 + endX - _handleW / 2,
                top: 0,
                bottom: 0,
                width: _handleW,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) {
                    final newX = (endX + d.delta.dx)
                        .clamp(startX + 2, _filmW);
                    widget.onEndChanged(_xToMs(newX,
                        minMs: widget.startMs + 200,
                        maxMs: widget.durationMs));
                  },
                  child: _Handle(color: c.peel, dir: _Dir.right),
                ),
              ),
            ]),
          );
        }),

        const SizedBox(height: Space.xs),

        // ── nudge buttons row ────────────────────────────────────────
        Row(
          children: [
            // Start – subtract
            _NudgeBtn(
              label: '−0.1s',
              onTap: () => widget.onStartChanged(
                  (widget.startMs - _nudgeMs).clamp(0, widget.endMs - 200)),
            ),
            // Start – add
            _NudgeBtn(
              label: '+0.1s',
              onTap: () => widget.onStartChanged(
                  (widget.startMs + _nudgeMs)
                      .clamp(0, widget.endMs - 200)),
            ),
            const Spacer(),
            // End – subtract
            _NudgeBtn(
              label: '−0.1s',
              onTap: () => widget.onEndChanged(
                  (widget.endMs - _nudgeMs)
                      .clamp(widget.startMs + 200, widget.durationMs)),
            ),
            // End – add
            _NudgeBtn(
              label: '+0.1s',
              onTap: () => widget.onEndChanged(
                  (widget.endMs + _nudgeMs)
                      .clamp(widget.startMs + 200, widget.durationMs)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Internal helpers ──────────────────────────────────────────────────────────

class _Filmstrip extends StatelessWidget {
  const _Filmstrip({required this.frames});
  final List<Uint8List> frames;

  @override
  Widget build(BuildContext context) {
    if (frames.isEmpty) {
      return ColoredBox(color: context.peel.surfaceHi);
    }
    return Row(
      children: frames
          .map(
            (b) => Expanded(
              child: Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true),
            ),
          )
          .toList(),
    );
  }
}

enum _Dir { left, right }

class _Handle extends StatelessWidget {
  const _Handle({required this.color, required this.dir});
  final Color color;
  final _Dir dir;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(dir == _Dir.left ? Radii.chip : 0),
          bottomLeft: Radius.circular(dir == _Dir.left ? Radii.chip : 0),
          topRight: Radius.circular(dir == _Dir.right ? Radii.chip : 0),
          bottomRight: Radius.circular(dir == _Dir.right ? Radii.chip : 0),
        ),
      ),
      child: Center(
        child: Container(
          width: 2,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _NudgeBtn extends StatelessWidget {
  const _NudgeBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: Space.xxs),
        padding: const EdgeInsets.symmetric(
            horizontal: Space.xs, vertical: Space.xxs),
        decoration: BoxDecoration(
          color: c.surfaceHi,
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        child: Text(
          label,
          style: monoStyle(context, size: 10, color: c.inkMuted),
        ),
      ),
    );
  }
}
