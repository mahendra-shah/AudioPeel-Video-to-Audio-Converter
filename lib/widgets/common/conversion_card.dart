import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/audio_file.dart';
import '../../utils/format_utils.dart';

/// A compact list tile for a completed conversion.
///
/// Shows an MP3 icon, file name, quality badge, size, date, and trailing
/// action buttons.
class ConversionCard extends StatelessWidget {
  const ConversionCard({
    required this.audioFile,
    this.onTap,
    this.onShare,
    this.onDelete,
    super.key,
  });

  /// The conversion record to display.
  final AudioFile audioFile;

  /// Called when the card body is tapped.
  final VoidCallback? onTap;

  /// Called when the share action is triggered.
  final VoidCallback? onShare;

  /// Called when the delete action is triggered.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingElement,
            vertical: AppConstants.spacingSmall + 4,
          ),
          child: Row(
            children: [
              // MP3 icon.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.spacingSmall,
                  ),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSmall + 4),

              // Name + meta.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audioFile.outputAudioName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(context, '${audioFile.quality.kbps} kbps'),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Text(
                          FormatUtils.fileSize(audioFile.fileSize),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Text(
                          FormatUtils.duration(audioFile.duration),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions.
              if (onShare != null)
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  onPressed: onShare,
                  tooltip: 'Share',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error.withValues(alpha: 0.7),
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
