import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_strings.dart';
import '../../models/audio_file.dart';
import '../../utils/format_utils.dart';
import 'audio_icon.dart';

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
    this.onDelete,
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

  /// Called when the delete action is triggered.
  final VoidCallback? onDelete;

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
            // Audio file thumbnail with music icon
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

            // 3-dot menu with all actions.
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.textTheme.bodySmall?.color,
              ),
              onSelected: (action) => _handleAction(action),
              itemBuilder: (_) => [
                if (onShare != null)
                  const PopupMenuItem(
                    value: 'share',
                    child: Text(AppStrings.shareConversion),
                  ),
                if (onRingtone != null)
                  const PopupMenuItem(
                    value: 'ringtone',
                    child: Text('Set as Ringtone'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(AppStrings.deleteConversion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'share':
        onShare?.call();
      case 'ringtone':
        onRingtone?.call();
      case 'delete':
        onDelete?.call();
    }
  }
}
