import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/audio_file.dart';
import '../../utils/format_utils.dart';

/// A compact list tile for the "Recent Conversions" section on the home
/// screen.
///
/// Matches the design: blue circle icon → filename → size · date → share.
class RecentConversionTile extends StatelessWidget {
  const RecentConversionTile({
    required this.audioFile,
    this.onTap,
    this.onShare,
    this.onRingtone,
    super.key,
  });

  /// The conversion record to display.
  final AudioFile audioFile;

  /// Called when the tile is tapped (opens the file or detail).
  final VoidCallback? onTap;

  /// Called when the share action is triggered.
  final VoidCallback? onShare;

  /// Called when the "Set as Ringtone" action is triggered.
  final VoidCallback? onRingtone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingSmall + 4,
        ),
        child: Row(
          children: [
            // Blue circle with music note icon.
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSmall + 4),

            // Filename + meta line.
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
                  Text(
                    '${FormatUtils.fileSize(audioFile.fileSize)}'
                    '  ·  '
                    '${FormatUtils.relativeDate(audioFile.createdAt)}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Ringtone icon.
            if (onRingtone != null)
              IconButton(
                icon: Icon(
                  Icons.ring_volume_outlined,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
                onPressed: onRingtone,
                tooltip: 'Set as Ringtone',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              ),

            // Share icon.
            if (onShare != null)
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: theme.textTheme.bodySmall?.color,
                ),
                onPressed: onShare,
                tooltip: 'Share',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
              ),
          ],
        ),
      ),
    );
  }
}
