import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:provider/provider.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../providers/player_provider.dart';

/// Persistent bottom mini-player that slides up when playback is active.
///
/// Reads [PlayerProvider] from context. Shows the track name, a format badge,
/// play/pause button with [AnimatedIcon], and a thin progress bar at the very
/// bottom edge. Height is 64 dp + bottom safe area.
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      // 0.0 = fully hidden below, 1.0 = fully visible
      value: 0.0,
      upperBound: 1.05, // spring overshoot headroom
      lowerBound: 0.0,
      duration: Motion.long,
    );
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _animateTo(bool visible) {
    if (visible == _wasVisible) return;
    _wasVisible = visible;
    final sim = SpringSimulation(
      Motion.pressSpring,
      _slideCtrl.value,
      visible ? 1.0 : 0.0,
      0.0,
    );
    _slideCtrl.animateWith(sim);
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final visible = player.hasTrack;

    WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(visible));

    final c = context.peel;
    final bottom = MediaQuery.paddingOf(context).bottom;
    const height = 64.0;

    return AnimatedBuilder(
      animation: _slideCtrl,
      builder: (context, child) {
        final t = _slideCtrl.value.clamp(0.0, 1.0);
        final translateY = (1 - t) * (height + bottom);
        return Transform.translate(
          offset: Offset(0, translateY),
          child: child,
        );
      },
      child: Material(
        color: c.surface,
        elevation: 8,
        shadowColor: Colors.black38,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Progress bar ──────────────────────────────────────
            _ProgressBar(player: player),

            // ── Content row ───────────────────────────────────────
            SizedBox(
              height: height,
              child: Padding(
                padding: EdgeInsets.only(
                  left: Space.gutter,
                  right: Space.gutter,
                  bottom: 0,
                ),
                child: Row(
                  children: [
                    // Waveform icon
                    Icon(Icons.graphic_eq_rounded,
                        color: c.peel, size: 28),

                    const SizedBox(width: Space.sm),

                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.title.isEmpty
                                ? 'Now Playing'
                                : player.title,
                            style: context.text.labelLarge
                                ?.copyWith(color: c.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (player.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              player.subtitle,
                              style: context.text.bodySmall
                                  ?.copyWith(color: c.inkMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: Space.sm),

                    // Play / Pause button
                    _PlayPauseButton(player: player),
                  ],
                ),
              ),
            ),

            // ── Safe area padding ─────────────────────────────────
            SizedBox(height: bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final duration = player.duration.inMilliseconds;

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snap) {
        final pos = snap.data?.inMilliseconds ?? 0;
        final fraction =
            duration > 0 ? (pos / duration).clamp(0.0, 1.0) : 0.0;

        return LayoutBuilder(
          builder: (_, constraints) => Stack(
            children: [
              // Track
              Container(height: 2, color: c.surfaceHi),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 2,
                width: constraints.maxWidth * fraction,
                color: c.peel,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Play/Pause button ─────────────────────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.player});
  final PlayerProvider player;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        if (player.currentUri != null) {
          player.toggle(
            player.currentUri!,
            title: player.title,
            subtitle: player.subtitle,
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.peel,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Motion.short,
            child: Icon(
              player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(player.isPlaying),
              color: c.onPeel,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
