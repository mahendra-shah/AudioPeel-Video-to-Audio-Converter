import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/audio_quality.dart';
import '../providers/conversion_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/common/banner_ad_widget.dart';
import 'converting_screen.dart';

/// Screen where the user configures the output name, quality, and starts
/// the conversion.
///
/// Expects [ConversionProvider] to already have a selected video.
class ConversionOptionsScreen extends StatefulWidget {
  const ConversionOptionsScreen({super.key});

  @override
  State<ConversionOptionsScreen> createState() =>
      _ConversionOptionsScreenState();
}

class _ConversionOptionsScreenState extends State<ConversionOptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Sync quality from settings when entering the screen.
    final settings = context.read<SettingsProvider>();
    final conversion = context.read<ConversionProvider>();
    final preferredQuality = AudioQuality.fromKbps(settings.defaultQualityKbps);
    conversion.selectQuality(preferredQuality);
  }

  /// Lets the user pick a different video without going back to home.
  Future<void> _selectAnotherVideo(BuildContext context) async {
    final conversion = context.read<ConversionProvider>();
    final picked = await conversion.selectVideo();
    if (!context.mounted) return;
    // If a new video was picked, refresh the page state.
    if (picked) {
      final settings = context.read<SettingsProvider>();
      conversion.selectQuality(
        AudioQuality.fromKbps(settings.defaultQualityKbps),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the video path so the list rebuilds with fresh keys
    // when the user picks a different video via "Change".
    final videoPath = context.watch<ConversionProvider>().selectedVideo?.path;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(AppStrings.conversionOptions),
        actions: [
          TextButton.icon(
            onPressed: () => _selectAnotherVideo(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Change'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingScreen,
              ),
              children: [
                const SizedBox(height: AppConstants.spacingElement),
                _VideoPreviewCard(key: ValueKey('preview_$videoPath')),
                const SizedBox(height: AppConstants.spacingElement),
                const _VideoInfoCard(),
                const SizedBox(height: AppConstants.spacingSection),
                _OutputNameSection(key: ValueKey('name_$videoPath')),
                const SizedBox(height: AppConstants.spacingSection),
                const _QualitySection(),
                const SizedBox(height: AppConstants.spacingSection),
                const _ConvertButton(),
                const SizedBox(height: AppConstants.spacingElement),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

// ─── Video Preview Card ───────────────────────────────────────────────

/// Rounded thumbnail with a semi-transparent play icon overlay.
class _VideoPreviewCard extends StatefulWidget {
  const _VideoPreviewCard({super.key});

  @override
  State<_VideoPreviewCard> createState() => _VideoPreviewCardState();
}

class _VideoPreviewCardState extends State<_VideoPreviewCard> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final video = context.read<ConversionProvider>().selectedVideo;
    if (video == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnail = data;
          _isLoading = false;
        });
      }
    } on Exception {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail area.
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Show actual thumbnail.
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_thumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppConstants.cardRadius - 1,
                  ),
                  child: Image.memory(
                    _thumbnail!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  Icons.videocam_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),

              // Play icon overlay.
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Text(
          AppStrings.videoPreview,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Video Info Card ──────────────────────────────────────────────────

/// Card showing Filename, Size, and Duration in labelled rows separated
/// by thin dividers.
class _VideoInfoCard extends StatelessWidget {
  const _VideoInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ConversionProvider>();

    final fileName = provider.selectedVideo?.uri.pathSegments.last ?? '';
    final sizeText = FormatUtils.fileSize(provider.videoSizeBytes);
    final durationText = FormatUtils.durationFromMs(provider.videoDurationMs);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(label: AppStrings.filename, value: fileName),
          Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _InfoRow(label: AppStrings.size, value: sizeText),
          Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _InfoRow(label: AppStrings.duration, value: durationText),
        ],
      ),
    );
  }
}

/// A single row inside the info card: left-aligned label, right-aligned
/// bold value.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingElement,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Output Name Section ──────────────────────────────────────────────

/// "Output Name" title and a text field with a ".mp3" suffix chip.
class _OutputNameSection extends StatefulWidget {
  const _OutputNameSection({super.key});

  @override
  State<_OutputNameSection> createState() => _OutputNameSectionState();
}

class _OutputNameSectionState extends State<_OutputNameSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ConversionProvider>();
    _controller = TextEditingController(text: provider.outputName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.outputName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        TextField(
          controller: _controller,
          onChanged: (value) {
            context.read<ConversionProvider>().updateOutputName(value);
          },
          decoration: InputDecoration(
            hintText: AppStrings.fileNameHint,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(
                right: AppConstants.spacingElement,
              ),
              child: Align(
                widthFactor: 1,
                child: Text(
                  AppStrings.mp3Extension,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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
      ],
    );
  }
}

// ─── Quality Section ──────────────────────────────────────────────────

/// "Audio Quality (kbps)" title with three toggle pills: 128, 192, 320.
class _QualitySection extends StatelessWidget {
  const _QualitySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ConversionProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.audioQuality,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Row(
          children: AudioQuality.values.map((quality) {
            final isSelected = quality == provider.quality;
            final isLast = quality == AudioQuality.high320;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: isLast ? 0 : AppConstants.spacingSmall,
                ),
                child: GestureDetector(
                  onTap: () => provider.selectQuality(quality),
                  child: AnimatedContainer(
                    duration: AppConstants.animationFast,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isDark
                          ? AppColors.cardDark
                          : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(
                        AppConstants.buttonRadius,
                      ),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                            ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${quality.kbps}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Convert Button ───────────────────────────────────────────────────

/// Full-width "⚡ CONVERT NOW" primary action button.
class _ConvertButton extends StatelessWidget {
  const _ConvertButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversionProvider>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: provider.isReadyToConvert
            ? () {
                final settings = context.read<SettingsProvider>();
                provider.startConversion(
                  autoDeleteOriginal: settings.autoDeleteOriginal,
                  normalizeVolume: settings.normalizeVolume,
                );
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ConvertingScreen(),
                  ),
                );
              }
            : null,
        icon: const Icon(Icons.bolt_rounded, size: 20),
        label: const Text(AppStrings.convertNow),
      ),
    );
  }
}
