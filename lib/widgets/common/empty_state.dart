import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// A vertically centred empty state with icon, title, subtitle, and
/// optional CTA button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert(icon != null || iconWidget != null,
            'Either icon or iconWidget must be provided');

  /// Large icon displayed at the top.
  final IconData? icon;

  /// Custom widget to display instead of icon.
  final Widget? iconWidget;

  /// Heading text.
  final String title;

  /// Supporting description text.
  final String subtitle;

  /// Optional CTA button label.
  final String? actionLabel;

  /// Callback when the CTA button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSection,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, size: 72, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: AppConstants.spacingElement),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppConstants.spacingSection),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
