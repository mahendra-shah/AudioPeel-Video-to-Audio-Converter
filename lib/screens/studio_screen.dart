import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
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
import '../widgets/trim_bar.dart';
import 'job_screen.dart';

/// Single-video conversion studio: trim, format, quality, enhance and output
/// settings all in one scrollable surface.
///
/// Constructed with a [MediaItem] that was already probed. The actual
/// conversion is delegated to [JobScreen] via [QueueProvider].
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key, required this.media});

  final MediaItem media;

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  // ── Options ───────────────────────────────────────────────────────────────
  late ConvertOptions _options;

  // ── Trim state ────────────────────────────────────────────────────────────
  late int _trimStart; // ms
  late int _trimEnd; // ms

  // ── Media assets ─────────────────────────────────────────────────────────
  Uint8List? _thumbnail;
  List<Uint8List> _filmstrip = const [];

  // ── Output name controller ────────────────────────────────────────────────
  late TextEditingController _nameCtrl;

  // ── Tag controllers ───────────────────────────────────────────────────────
  late TextEditingController _titleCtrl;
  late TextEditingController _artistCtrl;

  // ── Enhance section ───────────────────────────────────────────────────────
  bool _enhanceExpanded = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _options = settings.defaultOptions;
    _trimStart = 0;
    _trimEnd = widget.media.durationMs;

    _nameCtrl = TextEditingController(text: widget.media.baseName)
      ..addListener(_onNameChanged);
    _titleCtrl = TextEditingController(text: _options.title)
      ..addListener(_onTitleChanged);
    _artistCtrl = TextEditingController(text: _options.artist)
      ..addListener(_onArtistChanged);

    _fetchAssets();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    super.dispose();
  }

  // ── Asset loading ─────────────────────────────────────────────────────────

  Future<void> _fetchAssets() async {
    final thumb = await MediaBridge.thumbnail(
      widget.media.uri,
      ms: 0,
      width: 480,
    );
    if (!mounted) return;
    setState(() => _thumbnail = thumb);

    final strip = await MediaBridge.filmstrip(
      widget.media.uri,
      count: 10,
      width: 120,
    );
    if (!mounted) return;
    setState(() => _filmstrip = strip);
  }

  // ── Controller listeners ──────────────────────────────────────────────────

  void _onNameChanged() {
    final v = _nameCtrl.text;
    if (v != _options.fileName) {
      setState(() => _options = _options.copyWith(fileName: v));
    }
  }

  void _onTitleChanged() {
    final v = _titleCtrl.text;
    if (v != _options.title) {
      setState(() => _options = _options.copyWith(title: v));
    }
  }

  void _onArtistChanged() {
    final v = _artistCtrl.text;
    if (v != _options.artist) {
      setState(() => _options = _options.copyWith(artist: v));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _msToDisplay(int ms) => FormatUtils.durationFromMs(ms);

  int get _selectedDurationMs => _trimEnd - _trimStart;

  String _estimatedSize() {
    final bytes = _options.estimatedBytes(widget.media);
    return FormatUtils.fileSize(bytes);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _startConvert() {
    if (!widget.media.hasAudio) return;
    Haptics.commit();
    // Persist trim into options before pushing.
    final opts = _options.copyWith(
      trimStartMs: _trimStart,
      trimEndMs: () => _trimEnd >= widget.media.durationMs ? null : _trimEnd,
      fileName: _nameCtrl.text.trim().isEmpty
          ? widget.media.baseName
          : _nameCtrl.text.trim(),
    );
    Navigator.of(context).push(
      Motion.sharedAxis(
        JobScreen(items: [widget.media], options: opts),
      ),
    );
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
          'AudioPeel Studio',
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
          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: Space.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Space.sm),
                  _buildPreviewCard(peel),
                  const SizedBox(height: Space.sm),
                  _buildTrimSection(peel),
                  const SizedBox(height: Space.sm),
                  _buildFormatSection(peel),
                  if (!_options.format.lossless) ...[
                    const SizedBox(height: Space.sm),
                    _buildQualitySection(peel),
                  ],
                  const SizedBox(height: Space.sm),
                  _buildEnhanceSection(peel),
                  const SizedBox(height: Space.sm),
                  _buildOutputNameSection(peel),
                ],
              ),
            ),
          ),

          // ── Sticky Convert CTA ───────────────────────────────────
          _buildConvertCta(peel),
        ],
      ),
    );
  }

  // ── A. Video preview card ─────────────────────────────────────────────────

  Widget _buildPreviewCard(PeelColors peel) {
    final media = widget.media;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.chip),
              child: AspectRatio(
                aspectRatio: media.aspectRatio,
                child: _thumbnail != null
                    ? Image.memory(
                        _thumbnail!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : Container(
                        color: peel.surfaceHi,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: peel.peel,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: Space.sm),

            // Video name
            Text(
              media.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: Fonts.sans,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: peel.ink,
              ),
            ),
            const SizedBox(height: Space.xs),

            // Badge row
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                _badge(
                  peel,
                  label: _msToDisplay(media.durationMs),
                  icon: Icons.schedule_rounded,
                ),
                _badge(
                  peel,
                  label: FormatUtils.fileSize(media.sizeBytes),
                  icon: Icons.sd_storage_rounded,
                ),
                _badge(
                  peel,
                  label: media.audioCodecLabel,
                  icon: Icons.graphic_eq_rounded,
                ),
              ],
            ),

            // No audio warning
            if (!media.hasAudio) ...[
              const SizedBox(height: Space.xs),
              _warningChip(peel, 'No audio track · Convert disabled'),
            ],

            // AAC instant badge
            if (media.isAac) ...[
              const SizedBox(height: Space.xs),
              _instantChip(peel, 'AAC · Instant copy available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(
    PeelColors peel, {
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: peel.surfaceHi,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: peel.inkMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: Fonts.mono,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: peel.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningChip(PeelColors peel, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 4),
      decoration: BoxDecoration(
        color: peel.danger.withAlpha(30),
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: peel.danger.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 12, color: peel.danger),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: Fonts.sans,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: peel.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _instantChip(PeelColors peel, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 4),
      decoration: BoxDecoration(
        color: peel.groove.withAlpha(30),
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: peel.groove.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on_rounded, size: 12, color: peel.groove),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: Fonts.sans,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: peel.groove,
            ),
          ),
        ],
      ),
    );
  }

  // ── B. Trim section ───────────────────────────────────────────────────────

  Widget _buildTrimSection(PeelColors peel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: SectionCard(
        title: 'TRIM',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: duration display + reset button
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_msToDisplay(_trimStart)} → ${_msToDisplay(_trimEnd)}'
                    '  (${_msToDisplay(_selectedDurationMs)} selected)',
                    style: TextStyle(
                      fontFamily: Fonts.mono,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: peel.inkMuted,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Haptics.tap();
                    setState(() {
                      _trimStart = 0;
                      _trimEnd = widget.media.durationMs;
                    });
                  },
                  child: Text(
                    'Full',
                    style: TextStyle(
                      fontFamily: Fonts.sans,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: peel.peel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),

            // Film-strip trim bar
            TrimBar(
              durationMs: widget.media.durationMs,
              startMs: _trimStart,
              endMs: _trimEnd,
              frames: _filmstrip,
              onStartChanged: (ms) => setState(() => _trimStart = ms),
              onEndChanged: (ms) => setState(() => _trimEnd = ms),
            ),
          ],
        ),
      ),
    );
  }

  // ── C. Format section ─────────────────────────────────────────────────────

  Widget _buildFormatSection(PeelColors peel) {
    final formats = OutputFormat.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: SectionCard(
        title: 'FORMAT',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: PillSelector<OutputFormat>(
                items: formats,
                selected: _options.format,
                label: (f) {
                  if (f == OutputFormat.m4a && widget.media.isAac) {
                    return '${f.label} · Instant';
                  }
                  return f.label;
                },
                onChanged: (f) {
                  setState(() => _options = _options.copyWith(format: f));
                },
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
    );
  }

  // ── D. Quality section ────────────────────────────────────────────────────

  Widget _buildQualitySection(PeelColors peel) {
    final qualities = AudioQuality.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: SectionCard(
        title: 'QUALITY',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: PillSelector<AudioQuality>(
                items: qualities,
                selected: _options.quality,
                label: (q) => q.displayName,
                onChanged: (q) {
                  setState(() => _options = _options.copyWith(quality: q));
                },
              ),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Icon(Icons.storage_rounded, size: 13, color: peel.inkFaint),
                const SizedBox(width: 4),
                Text(
                  '≈ ${_estimatedSize()}',
                  style: TextStyle(
                    fontFamily: Fonts.mono,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: peel.inkMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── E. Enhance section ────────────────────────────────────────────────────

  Widget _buildEnhanceSection(PeelColors peel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Container(
        decoration: BoxDecoration(
          color: peel.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: peel.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Collapsible header ──────────────────────────────────
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

            // ── Collapsible body ────────────────────────────────────
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
      ),
    );
  }

  Widget _buildEnhanceBody(PeelColors peel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const SizedBox(height: Space.sm),

        // Normalize volume
        _enhanceSwitch(
          peel: peel,
          label: 'Normalize volume',
          description: 'Balance loudness to a standard level',
          value: _options.normalize,
          onChanged: (v) => setState(() => _options = _options.copyWith(normalize: v)),
        ),
        const SizedBox(height: Space.sm),

        // Volume boost
        _enhanceSlider(peel),
        const SizedBox(height: Space.sm),

        // Fade in
        _enhanceSwitch(
          peel: peel,
          label: 'Fade in',
          description: 'Gradually increase volume at start',
          value: _options.fadeIn,
          onChanged: (v) => setState(() => _options = _options.copyWith(fadeIn: v)),
        ),
        const SizedBox(height: Space.sm),

        // Fade out
        _enhanceSwitch(
          peel: peel,
          label: 'Fade out',
          description: 'Gradually decrease volume at end',
          value: _options.fadeOut,
          onChanged: (v) => setState(() => _options = _options.copyWith(fadeOut: v)),
        ),

        // Album art (MP3 only)
        if (_options.format == OutputFormat.mp3) ...[
          const SizedBox(height: Space.sm),
          _enhanceSwitch(
            peel: peel,
            label: 'Album art from video',
            description: 'Embed a video frame as cover art',
            value: _options.albumArt,
            onChanged: (v) => setState(() => _options = _options.copyWith(albumArt: v)),
          ),
        ],

        const SizedBox(height: Space.md),
        const Divider(height: 1),
        const SizedBox(height: Space.sm),

        // Title tag
        _tagField(
          peel: peel,
          label: 'Title',
          controller: _titleCtrl,
          hint: 'Song title',
        ),
        const SizedBox(height: Space.sm),

        // Artist tag
        _tagField(
          peel: peel,
          label: 'Artist',
          controller: _artistCtrl,
          hint: 'Artist name',
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

  Widget _enhanceSlider(PeelColors peel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Volume boost',
                style: TextStyle(
                  fontFamily: Fonts.sans,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: peel.ink,
                ),
              ),
            ),
            Text(
              '${_options.volume.toStringAsFixed(2)}×',
              style: TextStyle(
                fontFamily: Fonts.mono,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: peel.peel,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: peel.peel,
            inactiveTrackColor: peel.surfaceHi,
            thumbColor: peel.peel,
            overlayColor: peel.peel.withAlpha(40),
          ),
          child: Slider(
            value: _options.volume,
            min: 1.0,
            max: 2.0,
            divisions: 20,
            onChanged: (v) {
              setState(() => _options = _options.copyWith(volume: v));
            },
          ),
        ),
      ],
    );
  }

  Widget _tagField({
    required PeelColors peel,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: Fonts.sans,
        fontSize: 14,
        color: peel.ink,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: Fonts.sans,
          color: peel.inkMuted,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          fontFamily: Fonts.sans,
          color: peel.inkFaint,
          fontSize: 14,
        ),
        filled: true,
        fillColor: peel.surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
      ),
    );
  }

  // ── F. Output name section ────────────────────────────────────────────────

  Widget _buildOutputNameSection(PeelColors peel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: SectionCard(
        title: 'OUTPUT NAME',
        child: TextField(
          controller: _nameCtrl,
          maxLength: AppConstants.maxFileNameLength,
          style: TextStyle(
            fontFamily: Fonts.sans,
            fontSize: 14,
            color: peel.ink,
          ),
          decoration: InputDecoration(
            hintText: 'File name without extension',
            hintStyle: TextStyle(
              fontFamily: Fonts.sans,
              color: peel.inkFaint,
            ),
            filled: true,
            fillColor: peel.surfaceHi,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.chip),
              borderSide: BorderSide.none,
            ),
            counterStyle: TextStyle(
              fontFamily: Fonts.mono,
              fontSize: 11,
              color: peel.inkFaint,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: Space.sm,
            ),
          ),
        ),
      ),
    );
  }

  // ── G. Sticky Convert CTA ─────────────────────────────────────────────────

  Widget _buildConvertCta(PeelColors peel) {
    final enabled = widget.media.hasAudio;
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
                  'Convert',
                  style: TextStyle(
                    fontFamily: Fonts.sans,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: enabled ? peel.onPeel : peel.inkFaint,
                  ),
                ),
                Text(
                  '≈ ${_estimatedSize()}',
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
