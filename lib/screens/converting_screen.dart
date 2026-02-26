import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/conversion_task.dart';
import '../providers/conversion_provider.dart';
import '../utils/format_utils.dart';
import '../widgets/common/banner_ad_widget.dart';
import 'conversion_error_screen.dart';
import 'conversion_success_screen.dart';

/// Screen shown while FFmpeg is actively converting a video to MP3.
///
/// Layout: large progress ring with percentage, "CONVERTING..." label,
/// filename, time-remaining card, cancel button, banner ad.
class ConvertingScreen extends StatefulWidget {
  const ConvertingScreen({super.key});

  @override
  State<ConvertingScreen> createState() => _ConvertingScreenState();
}

class _ConvertingScreenState extends State<ConvertingScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversionProvider>();
    final task = provider.task;

    // If the conversion finishes, navigate away.
    if (!_hasNavigated && task != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigated) return;

        if (task.status == ConversionStatus.completed) {
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const ConversionSuccessScreen(),
            ),
          );
        } else if (task.status == ConversionStatus.failed) {
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const ConversionErrorScreen(),
            ),
          );
        } else if (task.status == ConversionStatus.cancelled) {
          _hasNavigated = true;
          Navigator.of(context).pop();
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _showCancelDialog,
          ),
          title: const Text(AppStrings.conversion),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingScreen,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppConstants.spacingSection),
                      _ProgressRingSection(
                        progress: provider.progress,
                        fileName: task?.inputVideoName ?? '',
                      ),
                      const SizedBox(height: AppConstants.spacingSection + 8),
                      _TimeRemainingCard(
                        progress: provider.progress,
                        videoDurationMs: provider.videoDurationMs,
                      ),
                      const SizedBox(height: AppConstants.spacingSection * 2),
                      _CancelButton(onCancel: _showCancelDialog),
                      const SizedBox(height: AppConstants.spacingElement),
                    ],
                  ),
                ),
              ),
            ),

            // Banner ad at the bottom.
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before cancelling the conversion.
  void _showCancelDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.cancelConversion),
        content: const Text(AppStrings.cancelConfirmation),
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
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<ConversionProvider>().cancelConversion();
        // Pop the screen immediately since cancellation may take a moment.
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.of(context).pop();
        }
      }
    });
  }
}

// ─── Progress Ring Section ────────────────────────────────────────────

/// Large circular progress ring (~240dp) with "CONVERTING..." label,
/// bold percentage, and filename inside.
class _ProgressRingSection extends StatelessWidget {
  const _ProgressRingSection({required this.progress, required this.fileName});

  /// Current progress from `0.0` to `1.0`.
  final double progress;

  /// The source video filename to display below the percentage.
  final String fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.cardDark : AppColors.dividerLight;
    final percentage = (progress * 100).round();

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Track ring.
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              color: trackColor,
              strokeCap: StrokeCap.round,
            ),
          ),

          // Active arc.
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              color: AppColors.primary,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
            ),
          ),

          // Centre content: label + percentage + filename.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.convertingStatus,
                style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 1.0),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  fileName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Time Remaining Card ──────────────────────────────────────────────

/// Card showing a clock icon and estimated time remaining.
class _TimeRemainingCard extends StatelessWidget {
  const _TimeRemainingCard({
    required this.progress,
    required this.videoDurationMs,
  });

  /// Current conversion progress from `0.0` to `1.0`.
  final double progress;

  /// Total video duration in milliseconds, used to estimate remaining time.
  final int videoDurationMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = _estimateRemaining();

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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 22,
            ),
          ),
          const SizedBox(width: AppConstants.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.timeRemaining,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '$remaining ${AppStrings.remaining}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estimates the remaining time as a formatted `mm:ss` string.
  String _estimateRemaining() {
    if (progress <= 0) {
      final totalSec = FormatUtils.estimateConversionTime(
        videoDurationMs ~/ 1000,
      );
      return FormatUtils.duration(totalSec);
    }

    final elapsedFraction = progress.clamp(0.01, 1.0);
    final totalEstimateSec = FormatUtils.estimateConversionTime(
      videoDurationMs ~/ 1000,
    );
    final remainingSec =
        ((1.0 - progress) / elapsedFraction * totalEstimateSec * progress)
            .round()
            .clamp(0, 9999);

    return FormatUtils.duration(remainingSec);
  }
}

// ─── Cancel Button ────────────────────────────────────────────────────

/// Red outlined "CANCEL ✕" button at the bottom of the screen.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  /// Called when the user taps the cancel button.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
        icon: const Icon(Icons.close_rounded, size: 18),
        label: const Text(AppStrings.cancel),
      ),
    );
  }
}
