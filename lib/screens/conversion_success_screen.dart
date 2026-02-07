import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../providers/ad_provider.dart';
import '../providers/conversion_provider.dart';
import '../providers/history_provider.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateHome(context);
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0F1E)
            : const Color.fromARGB(255, 240, 242, 245),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () => _navigateHome(context),
            ),
          ],
        ),
        body: const SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _ModernSuccessHeader(),
                      SizedBox(height: 40),
                      _ModernAudioPreviewCard(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ModernConvertAnotherButton(),
                    SizedBox(height: 16),
                    _ModernActionsRow(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
              BannerAdWidget(),
              SizedBox(height: 8),
            ],
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

// ─── Success Header ───────────────────────────────────────────────────

/// Green checkmark circle, "Conversion Complete!" title, and subtitle.
class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Green circle with checkmark.
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
        ),
        const SizedBox(height: AppConstants.spacingSection),
        Text(
          AppStrings.conversionComplete,
          style: theme.textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Text(
          AppStrings.fileReady,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
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
          // Music note icon in a rounded-square container.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: AppColors.primary,
              size: 28,
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
            icon: Icons.music_note_rounded,
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
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
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
            child: Icon(icon, color: AppColors.primary, size: 18),
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
        onPressed: () => _goHome(context),
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

// ═══════════════════════════════════════════════════════════════════════
// Modern Success Header with Checkmark Circle and "DONE"
// ═══════════════════════════════════════════════════════════════════════

class _ModernSuccessHeader extends StatelessWidget {
  const _ModernSuccessHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Animated circular checkmark (similar to progress screen)
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background gradient circle
              Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF5CA7E8),
                      Color(0xFF4A90E2),
                      Color(0xFF3A7BC8),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Subtle ring
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
              ),
              // Checkmark icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // "DONE" text
        Text(
          'DONE',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),
        // "Extraction Complete" heading
        Text(
          'Extraction Complete',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Modern Audio Preview Card with Rounded Design
// ═══════════════════════════════════════════════════════════════════════

class _ModernAudioPreviewCard extends StatelessWidget {
  const _ModernAudioPreviewCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<ConversionProvider>();
    final outputName = provider.task?.outputAudioName ?? 'audio.mp3';
    final outputPath = provider.task?.outputAudioPath ?? '';

    // Get file size and format
    final format = outputPath.split('.').last.toUpperCase();
    final quality = '${provider.quality.kbps}kbps';
    final fileSize = outputPath.isNotEmpty
        ? _getFileSizeSync(outputPath)
        : '0 MB';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Music icon with gradient purple background
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF7B3FF2), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outputName.length > 20
                      ? '${outputName.substring(0, 20)}...'
                      : outputName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '$fileSize • $format $quality',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Play button
          InkWell(
            onTap: () async {
              if (outputPath.isNotEmpty) {
                await OpenFilex.open(outputPath);
              }
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileSizeSync(String path) {
    try {
      final file = File(path);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return '0 MB';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Modern "CONVERT ANOTHER" Button
// ═══════════════════════════════════════════════════════════════════════

class _ModernConvertAnotherButton extends StatelessWidget {
  const _ModernConvertAnotherButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          final conversion = context.read<ConversionProvider>();
          conversion.reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          'CONVERT ANOTHER',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Modern Actions Row (Share & Delete)
// ═══════════════════════════════════════════════════════════════════════

class _ModernActionsRow extends StatelessWidget {
  const _ModernActionsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.read<ConversionProvider>();
    final outputPath = provider.task?.outputAudioPath ?? '';

    return Row(
      children: [
        // Share button
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (outputPath.isNotEmpty) {
                  await Share.shareXFiles([XFile(outputPath)]);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.transparent,
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: Text(
                'SHARE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Delete button
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, outputPath),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : Colors.black54,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.transparent,
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: Text(
                'DELETE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
        try {
          await context.read<StorageService>().deleteFile(path);
          if (context.mounted) {
            await context.read<HistoryProvider>().deleteConversionByPath(path);
            _goHome(context);
          }
        } on Exception {
          // Error handled silently
        }
      }
    });
  }
}
