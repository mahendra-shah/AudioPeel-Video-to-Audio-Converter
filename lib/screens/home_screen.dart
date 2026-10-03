import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/audio_file.dart';
import '../models/media_item.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_bridge.dart';
import '../utils/format_utils.dart';
import '../utils/logger.dart';
import '../widgets/mini_player.dart';
import '../widgets/pressable.dart';
import '../widgets/section_card.dart';
import 'batch_studio_screen.dart';
import 'studio_screen.dart';

/// Intent pre-selected when the user taps a quick-intent chip.
enum _QuickIntent {
  extract('Extract', Icons.music_note_rounded),
  cut('Cut & convert', Icons.content_cut_rounded),
  ringtone('Ringtone', Icons.notifications_active_rounded),
  batch('Batch', Icons.burst_mode_rounded);

  const _QuickIntent(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The "Convert" tab home screen.
///
/// Sections (top to bottom):
///  1. Hero — heading + Select Video CTA
///  2. Quick intents strip
///  3. Share tip banner (dismissible)
///  4. Recent conversions (up to 3)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HistoryProvider>().refresh();
    });
  }

  // ── Video picking ──────────────────────────────────────────────────────

  Future<void> _pickAndNavigate({
    bool multiple = false,
    _QuickIntent intent = _QuickIntent.extract,
  }) async {
    if (_picking) return;
    Haptics.commit();
    setState(() => _picking = true);
    try {
      final uris = await MediaBridge.pickVideos(multiple: multiple);
      if (!mounted || uris.isEmpty) return;

      if (uris.length == 1) {
        await _openSingle(uris.first, intent: intent);
      } else {
        await _openBatch(uris);
      }
    } on Exception catch (e) {
      Logger.warning('pick failed: $e', 'HomeScreen');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _openSingle(String uri, {_QuickIntent intent = _QuickIntent.extract}) async {
    final item = await _probeWithOverlay(uri);
    if (!mounted || item == null) return;
    _push(StudioScreen(media: item, intent: intent.name));
  }

  Future<void> _openBatch(List<String> uris) async {
    final items = await _batchProbeWithOverlay(uris);
    if (!mounted || items.isEmpty) return;
    _push(BatchStudioScreen(items: items));
  }

  void _push(Widget screen) {
    Navigator.of(context).push(Motion.sharedAxis(screen));
  }

  // ── Probe overlays ─────────────────────────────────────────────────────

  Future<MediaItem?> _probeWithOverlay(String uri) async {
    _showProbeDialog();
    try {
      return await MediaBridge.probe(uri);
    } on Exception catch (e) {
      Logger.warning('probe: $e', 'HomeScreen');
      return null;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<List<MediaItem>> _batchProbeWithOverlay(List<String> uris) async {
    _showProbeDialog();
    try {
      final items = <MediaItem>[];
      for (final uri in uris) {
        final item = await MediaBridge.probe(uri);
        if (item != null) items.add(item);
      }
      return items;
    } on Exception catch (e) {
      Logger.warning('batch probe: $e', 'HomeScreen');
      return [];
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showProbeDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProbeOverlayDialog(),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final history = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final player = context.watch<PlayerProvider>();
    final screenH = MediaQuery.sizeOf(context).height;

    // Bottom padding to clear the mini-player + nav bar.
    final bottomPad = MediaQuery.paddingOf(context).bottom + 72 + 68 + Space.md;

    return Scaffold(
      backgroundColor: c.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ───────────────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            floating: true,
            backgroundColor: c.canvas,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: Space.xxs,
                  ),
                  decoration: BoxDecoration(
                    gradient: c.peelGradient,
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Text(
                    'AudioPeel',
                    style: context.text.titleSmall?.copyWith(
                      color: c.onPeel,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Hero ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              constraints: BoxConstraints(minHeight: screenH * 0.38),
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.xl,
                Space.gutter,
                Space.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: Space.sm),
                  Text(
                    'Extract audio\nfrom any video',
                    textAlign: TextAlign.center,
                    style: context.text.displaySmall?.copyWith(
                      color: c.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    '100% offline · Nothing uploaded',
                    style: context.text.bodyMedium?.copyWith(
                      color: c.inkMuted,
                    ),
                  ),
                  const SizedBox(height: Space.xl),
                  _SelectVideoButton(
                    loading: _picking,
                    onPressed: () => _pickAndNavigate(multiple: true),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick intents ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.gutter,
                vertical: Space.xs,
              ),
              child: _QuickIntentStrip(
                onTap: (intent) {
                  switch (intent) {
                    case _QuickIntent.batch:
                      _pickAndNavigate(multiple: true, intent: intent);
                    case _QuickIntent.ringtone:
                      _pickAndNavigate(multiple: false, intent: intent);
                    default:
                      _pickAndNavigate(multiple: false, intent: intent);
                  }
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: Space.md)),

          // ── Share tip banner ──────────────────────────────────────────
          if (!settings.shareTipDismissed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: _ShareTipBanner(
                  onDismiss: () => settings.dismissShareTip(),
                ),
              ),
            ),

          if (!settings.shareTipDismissed)
            const SliverToBoxAdapter(child: SizedBox(height: Space.md)),

          // ── Recent conversions ────────────────────────────────────────
          if (history.recent.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  0,
                  Space.gutter,
                  Space.sm,
                ),
                child: Text(
                  'Recent',
                  style: context.text.titleSmall?.copyWith(color: c.ink),
                ),
              ),
            ),
            SliverList.separated(
              itemCount: history.recent.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: Space.xs),
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.gutter,
                ),
                child: _AudioFileTile(
                  file: history.recent[i],
                  index: i,
                  isPlaying: player.isPlayingUri(
                    history.recent[i].outputAudioPath,
                  ),
                  onTap: () {
                    final f = history.recent[i];
                    Haptics.tap();
                    context.read<PlayerProvider>().toggle(
                      f.outputAudioPath,
                      title: f.outputAudioName,
                      subtitle: f.qualityBadge,
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Bottom padding ────────────────────────────────────────────
          SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
        ],
      ),
    );
  }
}

// ── Select Video button ─────────────────────────────────────────────────────

class _SelectVideoButton extends StatelessWidget {
  const _SelectVideoButton({
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return Pressable(
      onPressed: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xxl,
          vertical: Space.lg,
        ),
        decoration: BoxDecoration(
          gradient: c.peelGradient,
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: [
            BoxShadow(
              color: c.peel.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Motion.short,
              child: loading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: c.onPeel,
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      key: const ValueKey('icon'),
                      color: c.onPeel,
                      size: 22,
                    ),
            ),
            const SizedBox(width: Space.sm),
            Text(
              'Select Video',
              style: context.text.labelLarge?.copyWith(
                color: c.onPeel,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick intent strip ──────────────────────────────────────────────────────

class _QuickIntentStrip extends StatelessWidget {
  const _QuickIntentStrip({required this.onTap});
  final void Function(_QuickIntent) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: _QuickIntent.values
            .map(
              (intent) => Padding(
                padding: const EdgeInsets.only(right: Space.xs),
                child: _IntentChip(
                  intent: intent,
                  onTap: () => onTap(intent),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _IntentChip extends StatelessWidget {
  const _IntentChip({required this.intent, required this.onTap});
  final _QuickIntent intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return Pressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        decoration: BoxDecoration(
          color: c.surfaceHi,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(intent.icon, size: 16, color: c.peel),
            const SizedBox(width: Space.xxs),
            Text(
              intent.label,
              style: context.text.labelMedium?.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Share tip banner ────────────────────────────────────────────────────────

class _ShareTipBanner extends StatelessWidget {
  const _ShareTipBanner({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.xs,
        Space.sm,
      ),
      decoration: BoxDecoration(
        color: c.groove.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.groove.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: c.groove, size: 20),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'Tip: Share any video to AudioPeel from Gallery, WhatsApp, or Files',
              style: context.text.bodySmall?.copyWith(color: c.ink),
            ),
          ),
          GestureDetector(
            onTap: () {
              Haptics.tap();
              onDismiss();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(Space.xs),
              child: Icon(Icons.close_rounded, size: 18, color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Audio file tile (recent strip) ─────────────────────────────────────────

class _AudioFileTile extends StatefulWidget {
  const _AudioFileTile({
    required this.file,
    required this.index,
    required this.onTap,
    required this.isPlaying,
  });

  final AudioFile file;
  final int index;
  final VoidCallback onTap;
  final bool isPlaying;

  @override
  State<_AudioFileTile> createState() => _AudioFileTileState();
}

class _AudioFileTileState extends State<_AudioFileTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Motion.medium);
    _fade = CurvedAnimation(parent: _ctrl, curve: Motion.standard);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Motion.emphasizedDecel));

    Future.delayed(Motion.staggerFor(widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _TileContent(
          file: widget.file,
          isPlaying: widget.isPlaying,
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.file,
    required this.isPlaying,
    required this.onTap,
  });

  final AudioFile file;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final f = file;

    return Pressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            // Play state indicator
            AnimatedContainer(
              duration: Motion.short,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isPlaying
                    ? c.peel.withValues(alpha: 0.15)
                    : c.surfaceHi,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isPlaying ? c.peel : c.inkMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: Space.sm),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.outputAudioName,
                    style: context.text.bodyMedium?.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Space.xxs),
                  Row(
                    children: [
                      // Format badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.peel.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          f.format.label,
                          style: context.text.labelSmall?.copyWith(
                            color: c.peel,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        FormatUtils.duration(f.duration),
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(width: Space.xs),
                      Text('·', style: context.text.bodySmall),
                      const SizedBox(width: Space.xs),
                      Text(
                        FormatUtils.fileSize(f.fileSize),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: Space.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: c.inkFaint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Probe overlay dialog ────────────────────────────────────────────────────

class _ProbeOverlayDialog extends StatelessWidget {
  const _ProbeOverlayDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xxl,
          vertical: Space.xl,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.peel, strokeWidth: 3),
            const SizedBox(height: Space.md),
            Text(
              'Reading video…',
              style: context.text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
