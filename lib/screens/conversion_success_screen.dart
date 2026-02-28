import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/common/audio_icon.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../providers/ad_provider.dart';
import '../providers/conversion_provider.dart';
import '../providers/history_provider.dart';
import '../screens/conversion_options_screen.dart';
import '../services/storage_service.dart';
import '../utils/format_utils.dart';
import '../widgets/common/banner_ad_widget.dart';

/// Screen shown after a successful conversion.
///
/// Layout: success checkmark, "Conversion Complete!" heading, audio
/// preview card with play button, file info card, "CONVERT ANOTHER"
/// button, and a split-capsule DELETE / SHARE button.
class ConversionSuccessScreen extends StatefulWidget {
  const ConversionSuccessScreen({super.key});

  @override
  State<ConversionSuccessScreen> createState() =>
      _ConversionSuccessScreenState();
}

class _ConversionSuccessScreenState extends State<ConversionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Show an interstitial ad after the success screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdProvider>().showInterstitialIfReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateHome(context),
          ),
          title: const Text(AppStrings.conversionComplete),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingScreen,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: const [
                      SizedBox(height: AppConstants.spacingElement),
                      _SuccessHeader(),
                      SizedBox(height: AppConstants.spacingSection),
                      _AudioPreviewCard(),
                      SizedBox(height: AppConstants.spacingElement),
                      _FileInfoCard(),
                      SizedBox(height: AppConstants.spacingSection),
                    ],
                  ),
                ),
                const _ConvertAnotherButton(),
                const SizedBox(height: AppConstants.spacingSmall + 4),
                const _SplitCapsuleActions(),
                const SizedBox(height: AppConstants.spacingSmall),
                const BannerAdWidget(),
                const SizedBox(height: AppConstants.spacingSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Resets state and pops back to the home screen.
  static void _navigateHome(BuildContext context) {
    _goHome(context);
  }
}

/// Resets conversion state and pops back to the home screen.
void _goHome(BuildContext context) {
  context.read<ConversionProvider>().reset();
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Opens the file picker immediately for a new conversion.
/// If the user picks a file, navigates straight to options screen.
/// If the user cancels, falls back to home.
Future<void> _convertAnother(BuildContext context) async {
  final provider = context.read<ConversionProvider>();
  provider.reset();

  final picked = await provider.selectVideo();
  if (!context.mounted) return;

  if (picked) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ConversionOptionsScreen(),
      ),
    );
  } else {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ─── Success Header ───────────────────────────────────────────────────

/// Green checkmark circle, "Conversion Complete!" title, and subtitle.
class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Green circle with checkmark — bounces in with elastic scale + shimmer.
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.success,
            size: 48,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.0, 0.0),
              end: const Offset(1.0, 1.0),
              duration: 650.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(
              delay: 500.ms,
              duration: 700.ms,
              color: AppColors.success.withValues(alpha: 0.45),
              angle: 0.3,
            ),
        const SizedBox(height: AppConstants.spacingSection),
        Text(
          AppStrings.conversionComplete,
          style: theme.textTheme.displayLarge,
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 380.ms, duration: 380.ms)
            .slideY(
              begin: 0.25,
              end: 0,
              delay: 380.ms,
              duration: 380.ms,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: AppConstants.spacingSmall),
        Text(
          AppStrings.fileReady,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 560.ms, duration: 300.ms),
      ],
    );
  }
}

// ─── Audio Preview Card ───────────────────────────────────────────────

/// Redesigned card with a music icon, file name, duration, and a play
/// button that opens the MP3 in an external player.
class _AudioPreviewCard extends StatelessWidget {
  const _AudioPreviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<ConversionProvider>();
    final durationText = FormatUtils.durationFromMs(provider.videoDurationMs);
    final outputName = provider.task?.outputAudioName ?? 'audio.mp3';
    final outputPath = provider.task?.outputAudioPath ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingElement),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          // Branded audio icon in a rounded-square container.
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.audiotrack_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSmall + 4),

          // File name + duration.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outputName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  durationText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Play button — opens in external player.
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openInExternalPlayer(context, outputPath),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the converted MP3 file in the device's default music player.
  void _openInExternalPlayer(BuildContext context, String path) {
    if (path.isEmpty) return;
    OpenFilex.open(path, type: 'audio/mpeg');
  }
}

// ─── File Info Card ───────────────────────────────────────────────────

/// Card showing FILE NAME, SAVED TO path, and SIZE — each row has a
/// capsule-shaped icon container.
class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<ConversionProvider>();
    final task = provider.task;

    final fileName = task?.outputAudioName ?? '';
    final savedPath = task?.outputAudioPath ?? '';
    final fileSize = StorageService().fileSize(task?.outputAudioPath ?? '');
    final sizeText = FormatUtils.fileSize(fileSize);

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
          _FileInfoRow(
            iconWidget: const AudioIcon(size: 18, color: AppColors.primary, showContainer: false),
            label: AppStrings.fileNameLabel,
            value: fileName,
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _FileInfoRow(
            icon: Icons.folder_rounded,
            label: AppStrings.savedToLabel,
            value: savedPath,
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          _FileInfoRow(
            icon: Icons.storage_rounded,
            label: AppStrings.sizeLabel,
            value: sizeText,
          ),
        ],
      ),
    );
  }
}

/// A single row inside the file info card: capsule-shaped icon, uppercase
/// label, and bold value.
class _FileInfoRow extends StatelessWidget {
  const _FileInfoRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
  }) : assert(icon != null || iconWidget != null,
            'Either icon or iconWidget must be provided');

  final IconData? icon;
  final Widget? iconWidget;
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
        children: [
          // Capsule-shaped icon container.
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconWidget ?? Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppConstants.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Convert Another Button ───────────────────────────────────────────

/// Full-width primary "↻ CONVERT ANOTHER" button.
class _ConvertAnotherButton extends StatelessWidget {
  const _ConvertAnotherButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _convertAnother(context),
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(AppStrings.convertAnother),
      ),
    );
  }
}

// ─── Split-Capsule Delete / Share ─────────────────────────────────────

/// A single capsule-shaped container with DELETE on the left and SHARE
/// on the right, separated by a thin divider.
class _SplitCapsuleActions extends StatelessWidget {
  const _SplitCapsuleActions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<ConversionProvider>();
    final outputPath = provider.task?.outputAudioPath ?? '';

    return Container(
      height: AppConstants.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius - 1),
        child: Row(
          children: [
            // DELETE half.
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _confirmDelete(context, outputPath),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.delete,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Thin vertical divider.
            Container(
              width: 1,
              height: AppConstants.buttonHeight * 0.5,
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),

            // SHARE half.
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    SharePlus.instance.share(
                      ShareParams(files: [XFile(outputPath)]),
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.share,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog, then deletes the file and navigates home.
  void _confirmDelete(BuildContext context, String path) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteConversion),
        content: const Text(AppStrings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        // Delete the file from disk AND the database record.
        await StorageService().deleteFile(path);
        if (context.mounted) {
          await context.read<HistoryProvider>().deleteConversionByPath(path);
        }
        if (context.mounted) {
          _goHome(context);
        }
      }
    });
  }
}
