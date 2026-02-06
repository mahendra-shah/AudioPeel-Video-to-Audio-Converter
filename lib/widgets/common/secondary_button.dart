import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Full-width outlined button for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  /// Button label text.
  final String label;

  /// Tap callback. Pass `null` to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(label),
            ],
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
