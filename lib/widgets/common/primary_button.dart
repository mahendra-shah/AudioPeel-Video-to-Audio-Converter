import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Full-width primary action button with optional leading icon.
///
/// Uses the theme's [ElevatedButton] style (primary blue background,
/// white text, 52dp height, 12dp radius).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  /// Button label text.
  final String label;

  /// Tap callback. Pass `null` to disable.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Replaces the label with a spinner when `true`.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : icon != null
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
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
