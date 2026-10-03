import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/audio_quality.dart';
import '../models/convert_options.dart';
import '../models/media_item.dart';
import '../models/output_format.dart';
import '../providers/queue_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_bridge.dart';
import '../utils/format_utils.dart';
import '../widgets/pill_selector.dart';
import '../widgets/pressable.dart';
import '../widgets/section_card.dart';
import 'job_screen.dart';

/// Batch conversion studio — accepts a list of [MediaItem]s and lets the user
/// reorder/remove them, choose shared format / quality / enhance settings,
/// then kick off all conversions via [QueueProvider].
class BatchStudioScreen extends StatefulWidget {
  const BatchStudioScreen({super.key, required this.items});

  final List<MediaItem> items;

  @override
  State<BatchStudioScreen> createState() => _BatchStudioScreenState();
}

class _BatchStudioScreenState extends State<BatchStudioScreen> {
  // ── Item list (mutable — user can reorder / remove) ───────────────────────
  late List<MediaItem> _items;

  // ── Per-item thumbnails ───────────────────────────────────────────────────
  final Map<String, Uint8List> _thumbs = {};

  // ── Shared options ────────────────────────────────────────────────────────
  late ConvertOptions _options;

  // ── Enhance section ───────────────────────────────────────────────────────
  bool _enhanceExpanded = false;

  @override
  void initState() {
    super.initState();
    _items = List<MediaItem>.from(widget.items);
    final settings = context.read<SettingsProvider>();
    _options = settings.defaultOptions.copyWith(
      trimStartMs: 0,
      trimEndMs: () => null, // no trim in batch mode
    );
    _fetchThumbnails();
  }

  // ── Thumbnail loading ─────────────────────────────────────────────────────

  Future<void> _fetchThumbnails() async {
    for (final item in _items) {
      if (_thumbs.containsKey(item.uri)) continue;
      final bytes = await MediaBridge.thumbnail(item.uri, ms: 0, width: 120);
      if (!mounted) return;
      if (bytes != null) {
        setState(() => _thumbs[item.uri] = bytes);
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int get _audioItemCount => _items.where((i) => i.hasAudio).length;

  String _estimatedTotal() {
    int total = 0;
    for (final item in _items) {
      if (item.hasAudio) total += _options.estimatedBytes(item);
    }
    return FormatUtils.fileSize(total);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _startConvert() {
    if (_audioItemCount == 0) return;
    Haptics.commit();
    final validItems = _items.where((i) => i.hasAudio).toList();
    Navigator.of(context).push(
      Motion.sharedAxis(
        JobScreen(items: validItems, options: _options),
      ),
    );
  }

  // ── Remove confirm ────────────────────────────────────────────────────────

  Future<bool> _confirmRemove(MediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final peel = ctx.peel;
        return AlertDialog(
          backgroundColor: peel.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          title: Text(
            'Remove video?',
            style: TextStyle(
              fontFamily: Fonts.sans,
              fontWeight: FontWeight.w700,
              color: peel.ink,
            ),
          ),
          content: Text(
            item.name,
            style: TextStyle(
              fontFamily: Fonts.sans,
              color: peel.inkMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Keep',
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  color: peel.inkMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Remove',
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  fontWeight: FontWeight.w700,
                  color: peel.danger,
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final peel = context.peel;

    return Scaffold(
      backgroundColor: peel.canvas,
      appBar: AppBar(
        backgroundColor: peel.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: peel.ink),
        title: Text(
          'Batch Convert (${_items.length} video${_items.length == 1 ? '' : 's'})',
          style: TextStyle(
            fontFamily: Fonts.sans,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: peel.ink,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── A. Reorderable video list ────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.sm,
                    Space.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'VIDEOS',
                      style: TextStyle(
                        fontFamily: Fonts.sans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: peel.inkFaint,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.xs,
                    Space.gutter,
                    0,
                  ),
                  sliver: _buildItemList(peel),
                ),

                // ── B. Format ────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.sm,
                    Space.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: SectionCard(
                      title: 'FORMAT',
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: PillSelector<OutputFormat>(
                              items: OutputFormat.values,
                              selected: _options.format,
                              label: (f) => f.label,
                              onChanged: (f) => setState(
                                () => _options = _options.copyWith(format: f),
                              ),
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            _options.format.blurb,
                            style: TextStyle(
                              fontFamily: Fonts.sans,
                              fontSize: 12,
                              color: peel.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── C. Quality (hidden for lossless) ─────────────────
                if (!_options.format.lossless)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.sm,
                      Space.gutter,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: SectionCard(
                        title: 'QUALITY',
                        margin: EdgeInsets.zero,
                        child: SizedBox(
                          width: double.infinity,
                          child: PillSelector<AudioQuality>(
                            items: AudioQuality.values,
                            selected: _options.quality,
                            label: (q) => q.displayName,
                            onChanged: (q) => setState(
                              () => _options = _options.copyWith(quality: q),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── D. Enhance ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.sm,
                    Space.gutter,
                    Space.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildEnhanceSection(peel),
                  ),
                ),
              ],
            ),
          ),

          // ── Sticky Convert CTA ─────────────────────────────────────
          _buildConvertCta(peel),
        ],
      ),
    );
  }

  // ── Video list ────────────────────────────────────────────────────────────

  Widget _buildItemList(PeelColors peel) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = _items[index];
          return _BatchItemRow(
            key: ValueKey(item.uri),
            item: item,
            thumbnail: _thumbs[item.uri],
            onRemove: () async {
              final ok = await _confirmRemove(item);
              if (ok && mounted) {
                setState(() => _items.removeAt(index));
              }
            },
          );
        },
        childCount: _items.length,
      ),
    );
  }

  // ── Enhance section ───────────────────────────────────────────────────────

  Widget _buildEnhanceSection(PeelColors peel) {
    return Container(
      decoration: BoxDecoration(
        color: peel.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: peel.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(Radii.card),
            onTap: () {
              Haptics.tap();
              setState(() => _enhanceExpanded = !_enhanceExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.gutter,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'ENHANCE',
                      style: TextStyle(
                        fontFamily: Fonts.sans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: peel.inkFaint,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _enhanceExpanded ? 0 : -0.25,
                    duration: Motion.short,
                    child: Icon(
                      Icons.expand_less_rounded,
                      size: 20,
                      color: peel.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.emphasizedDecel,
            alignment: Alignment.topCenter,
            child: _enhanceExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      0,
                      Space.gutter,
                      Space.md,
                    ),
                    child: _buildEnhanceBody(peel),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhanceBody(PeelColors peel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const SizedBox(height: Space.sm),
        _enhanceSwitch(
          peel: peel,
          label: 'Normalize volume',
          description: 'Balance loudness across all files',
          value: _options.normalize,
          onChanged: (v) =>
              setState(() => _options = _options.copyWith(normalize: v)),
        ),
        const SizedBox(height: Space.sm),
        _enhanceSwitch(
          peel: peel,
          label: 'Fade in',
          description: 'Gradually increase volume at start',
          value: _options.fadeIn,
          onChanged: (v) =>
              setState(() => _options = _options.copyWith(fadeIn: v)),
        ),
        const SizedBox(height: Space.sm),
        _enhanceSwitch(
          peel: peel,
          label: 'Fade out',
          description: 'Gradually decrease volume at end',
          value: _options.fadeOut,
          onChanged: (v) =>
              setState(() => _options = _options.copyWith(fadeOut: v)),
        ),
      ],
    );
  }

  Widget _enhanceSwitch({
    required PeelColors peel,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: peel.ink,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  fontSize: 12,
                  color: peel.inkMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {
            Haptics.select();
            onChanged(v);
          },
          activeColor: peel.peel,
        ),
      ],
    );
  }

  // ── Convert CTA ───────────────────────────────────────────────────────────

  Widget _buildConvertCta(PeelColors peel) {
    final enabled = _audioItemCount > 0;
    final count = _audioItemCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.sm,
          Space.gutter,
          Space.lg,
        ),
        child: Pressable(
          onTap: enabled ? _startConvert : null,
          child: AnimatedContainer(
            duration: Motion.short,
            height: 60,
            decoration: BoxDecoration(
              gradient: enabled ? peel.peelGradient : null,
              color: enabled ? null : peel.surfaceHi,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Convert $count video${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontFamily: Fonts.sans,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: enabled ? peel.onPeel : peel.inkFaint,
                  ),
                ),
                Text(
                  '≈ ${_estimatedTotal()} total',
                  style: TextStyle(
                    fontFamily: Fonts.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? peel.onPeel.withAlpha(180)
                        : peel.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Batch item row ────────────────────────────────────────────────────────────

class _BatchItemRow extends StatelessWidget {
  const _BatchItemRow({
    super.key,
    required this.item,
    required this.thumbnail,
    required this.onRemove,
  });

  final MediaItem item;
  final Uint8List? thumbnail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final peel = context.peel;

    return Dismissible(
      key: ValueKey(item.uri),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        // The parent handles confirm dialog
        onRemove();
        return false; // parent manages removal
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.lg),
        decoration: BoxDecoration(
          color: peel.danger.withAlpha(40),
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Icon(Icons.delete_rounded, color: peel.danger),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        decoration: BoxDecoration(
          color: peel.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: peel.line, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.chip),
                child: SizedBox(
                  width: 56,
                  height: 42,
                  child: thumbnail != null
                      ? Image.memory(
                          thumbnail!,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        )
                      : Container(
                          color: peel.surfaceHi,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: peel.peel,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: Space.sm),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: Fonts.sans,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: peel.ink,
                            ),
                          ),
                        ),
                        // No-audio warning icon
                        if (!item.hasAudio)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: Space.xxs),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 15,
                              color: peel.warning,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${FormatUtils.durationFromMs(item.durationMs)}  ·  '
                      '${FormatUtils.fileSize(item.sizeBytes)}',
                      style: TextStyle(
                        fontFamily: Fonts.mono,
                        fontSize: 11,
                        color: peel.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Drag handle (visual only — reorder handled below)
              Padding(
                padding: const EdgeInsets.only(left: Space.xs),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: peel.inkFaint,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
