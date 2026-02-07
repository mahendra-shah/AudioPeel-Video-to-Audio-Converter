import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/audio_format.dart';
import '../models/audio_quality.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/common/banner_ad_widget.dart';
import 'converting_screen.dart';

/// Redesigned conversion options screen with immersive video preview.
///
/// Features:
/// - Large video preview covering upper area with overlay info
/// - Video metadata (quality, format, duration) displayed on preview
/// - Audio quality selector (128k, 192k, 320k, Lossless)
/// - Output format selector (MP3, WAV, FLAC, M4A)
/// - Extract audio action button
class ConversionOptionsScreen extends StatefulWidget {
  const ConversionOptionsScreen({super.key});

  @override
  State<ConversionOptionsScreen> createState() =>
      _ConversionOptionsScreenState();
}

class _ConversionOptionsScreenState extends State<ConversionOptionsScreen> {
  Uint8List? _thumbnail;
  bool _isLoadingThumbnail = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    // Sync quality and format from settings when entering the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      final conversion = context.read<ConversionProvider>();
      final preferredQuality = AudioQuality.fromKbps(
        settings.defaultQualityKbps,
      );
      conversion.selectQuality(preferredQuality);
      conversion.selectFormat(settings.defaultFormat);
    });
  }

  Future<void> _loadThumbnail() async {
    final video = context.read<ConversionProvider>().selectedVideo;
    if (video == null) {
      if (mounted) setState(() => _isLoadingThumbnail = false);
      return;
    }

    try {
      final data = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 1024,
        quality: 85,
      );
      if (mounted) {
        setState(() {
          _thumbnail = data;
          _isLoadingThumbnail = false;
        });
      }
    } on Exception {
      if (mounted) setState(() => _isLoadingThumbnail = false);
    }
  }

  /// Lets the user pick a different video.
  Future<void> _selectAnotherVideo(BuildContext context) async {
    final conversion = context.read<ConversionProvider>();
    final settings = context.read<SettingsProvider>();
    final picked = await conversion.selectVideo();
    if (!context.mounted) return;
    if (picked) {
      // Reload thumbnail and reset settings
      setState(() {
        _thumbnail = null;
        _isLoadingThumbnail = true;
      });
      await _loadThumbnail();
      if (mounted) {
        conversion.selectQuality(
          AudioQuality.fromKbps(settings.defaultQualityKbps),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversionProvider>();
    final settings = context.watch<SettingsProvider>();
    final video = provider.selectedVideo;

    if (video == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('No Video Selected')),
        body: const Center(child: Text('Please select a video first.')),
      );
    }

    final fileName = video.uri.pathSegments.last;
    final durationText = FormatUtils.durationFromMs(provider.videoDurationMs);

    // Extract video metadata (simplified)
    const videoQuality = '1080p'; // Could be extracted from video metadata
    final videoFormat = fileName.split('.').last.toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.grey.shade50,
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // UPPER SECTION: Immersive Video Preview
          // ═══════════════════════════════════════════════════════════
          _VideoPreviewSection(
            thumbnail: _thumbnail,
            isLoading: _isLoadingThumbnail,
            fileName: fileName,
            videoQuality: videoQuality,
            videoFormat: videoFormat,
            duration: durationText,
            onBack: () => Navigator.of(context).pop(),
            onChangeVideo: () => _selectAnotherVideo(context),
          ),

          // ═══════════════════════════════════════════════════════════
          // LOWER SECTION: Audio Options & Action Button
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: _AudioOptionsSection(
              outputName: provider.outputName,
              onOutputNameChanged: (name) => provider.updateOutputName(name),
              selectedQuality: provider.quality,
              selectedFormat: provider.format,
              onQualityChanged: (quality) => provider.selectQuality(quality),
              onFormatChanged: (format) {
                provider.selectFormat(format);
                settings.setDefaultFormat(format);
              },
              onExtractAudio: () {
                provider.startConversion(
                  autoDeleteOriginal: settings.autoDeleteOriginal,
                  normalizeVolume: settings.normalizeVolume,
                );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConvertingScreen(),
                  ),
                );
              },
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // BANNER AD
          // ═══════════════════════════════════════════════════════════
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// UPPER SECTION: Video Preview with Overlay Info
// ═══════════════════════════════════════════════════════════════════════

class _VideoPreviewSection extends StatelessWidget {
  const _VideoPreviewSection({
    required this.thumbnail,
    required this.isLoading,
    required this.fileName,
    required this.videoQuality,
    required this.videoFormat,
    required this.duration,
    required this.onBack,
    required this.onChangeVideo,
  });

  final Uint8List? thumbnail;
  final bool isLoading;
  final String fileName;
  final String videoQuality;
  final String videoFormat;
  final String duration;
  final VoidCallback onBack;
  final VoidCallback onChangeVideo;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    // Make preview section take ~45% of screen height
    final previewHeight = mediaQuery.size.height * 0.45;

    return Container(
      height: previewHeight,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          // ──────────────────────────────────────────────────────────
          // Background: Video Thumbnail
          // ──────────────────────────────────────────────────────────
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (thumbnail != null)
            Positioned.fill(child: Image.memory(thumbnail!, fit: BoxFit.cover))
          else
            Center(
              child: Icon(
                Icons.videocam_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),

          // ──────────────────────────────────────────────────────────
          // Gradient Overlays for Better Text Visibility
          // ──────────────────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // Top Bar: Back Button & Change Video
          // ──────────────────────────────────────────────────────────
          Positioned(
            top: statusBarHeight + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                // Title
                const Text(
                  'CONVERSION SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                // Change video button
                IconButton(
                  onPressed: onChangeVideo,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // Center: Play Button Overlay
          // ──────────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          // ──────────────────────────────────────────────────────────
          // Bottom: Video Info Overlay
          // ──────────────────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Music Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // File name
                Text(
                  _getFileNameWithoutExtension(fileName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Metadata row: Quality • Format • Duration
                Row(
                  children: [
                    _MetadataBadge(text: videoQuality),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    _MetadataBadge(text: videoFormat),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFileNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return fileName;
    return fileName.substring(0, lastDot);
  }
}

/// Small pill badge for video metadata (quality, format).
class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// LOWER SECTION: Audio Quality & Format Options
// ═══════════════════════════════════════════════════════════════════════

class _AudioOptionsSection extends StatelessWidget {
  const _AudioOptionsSection({
    required this.outputName,
    required this.onOutputNameChanged,
    required this.selectedQuality,
    required this.selectedFormat,
    required this.onQualityChanged,
    required this.onFormatChanged,
    required this.onExtractAudio,
  });

  final String outputName;
  final ValueChanged<String> onOutputNameChanged;
  final AudioQuality selectedQuality;
  final AudioFormat selectedFormat;
  final ValueChanged<AudioQuality> onQualityChanged;
  final ValueChanged<AudioFormat> onFormatChanged;
  final VoidCallback onExtractAudio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0F1E)
            : const Color.fromARGB(139, 255, 255, 255),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────────────────────────────────────────────────
            // OUTPUT NAME Section
            // ──────────────────────────────────────────────────────
            Text(
              'OUTPUT NAME',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                text: outputName,
              )..selection = TextSelection.collapsed(offset: outputName.length),
              onChanged: onOutputNameChanged,
              decoration: InputDecoration(
                hintText: 'Enter file name',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Align(
                    widthFactor: 1,
                    child: Text(
                      '.${selectedFormat.extension}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLength: AppConstants.maxFileNameLength,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
            ),

            const SizedBox(height: 24),

            // ──────────────────────────────────────────────────────
            // AUDIO QUALITY Section
            // ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AUDIO QUALITY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  'Auto-detect best',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quality options row
            Row(
              children: [
                _QualityOption(
                  label: '128k',
                  isSelected: selectedQuality == AudioQuality.low128,
                  onTap: () => onQualityChanged(AudioQuality.low128),
                ),
                const SizedBox(width: 12),
                _QualityOption(
                  label: '192k',
                  isSelected: selectedQuality == AudioQuality.medium192,
                  onTap: () => onQualityChanged(AudioQuality.medium192),
                ),
                const SizedBox(width: 12),
                _QualityOption(
                  label: '320k',
                  isSelected: selectedQuality == AudioQuality.high320,
                  onTap: () => onQualityChanged(AudioQuality.high320),
                ),
                const SizedBox(width: 12),
                _QualityOption(
                  label: 'Lossless',
                  icon: Icons.star,
                  isSelected: false, // Not yet implemented
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lossless quality coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ──────────────────────────────────────────────────────
            // OUTPUT FORMAT Section
            // ──────────────────────────────────────────────────────
            Text(
              'OUTPUT FORMAT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            // Format options - Horizontal scrollable list
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AudioFormat.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final format = AudioFormat.values[index];
                  return _FormatOption(
                    label: format.displayName,
                    isSelected: selectedFormat == format,
                    onTap: () => onFormatChanged(format),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ──────────────────────────────────────────────────────
            // EXTRACT AUDIO Button
            // ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onExtractAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXTRACT AUDIO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.music_note_rounded, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quality Option Button ─────────────────────────────────────────────

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                ? const Color(0xFF1A1A2E)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(
                    color: isDark ? Colors.transparent : Colors.grey.shade300,
                  ),
          ),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isDark
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : isDark
                            ? Colors.grey
                            : Colors.grey.shade600,
                      ),
                    ],
                  )
                : Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isDark
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Format Option Button ──────────────────────────────────────────────

class _FormatOption extends StatelessWidget {
  const _FormatOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
              ? const Color(0xFF1A1A2E)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(
                  color: isDark ? Colors.transparent : Colors.grey.shade300,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : isDark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
