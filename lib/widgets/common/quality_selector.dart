import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/audio_quality.dart';

/// A row of three toggle buttons for selecting audio quality.
///
/// Each option is an equal-width pill showing the kbps value and label.
class QualitySelector extends StatelessWidget {
  const QualitySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The currently selected quality.
  final AudioQuality selected;

  /// Called when the user taps a different option.
  final ValueChanged<AudioQuality> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: AudioQuality.values.map((quality) {
        final isSelected = quality == selected;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: quality != AudioQuality.high320
                  ? AppConstants.spacingSmall
                  : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(quality),
              child: AnimatedContainer(
                duration: AppConstants.animationFast,
                height: 48,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quality.displayName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quality.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isSelected
                            ? Colors.white70
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
