import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/common/audio_icon.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../providers/conversion_provider.dart';
import '../widgets/common/banner_ad_widget.dart';

/// Screen shown when a conversion fails.
///
/// Layout: broken-disc illustration with error badge, "Something went
/// wrong" heading, description, error code chip, "Retry Conversion"
/// button, and "Select Another Video" button.
class ConversionErrorScreen extends StatelessWidget {
  const ConversionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ConversionProvider>();
    final errorMessage = provider.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateHome(context),
        ),
        title: const Text(AppStrings.conversionError),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingScreen,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _ErrorIllustration(),
                        const SizedBox(height: AppConstants.spacingSection),
                        _ErrorHeading(),
                        const SizedBox(height: AppConstants.spacingSmall + 4),
                        _ErrorDescription(),
                        if (errorMessage != null &&
                            errorMessage.isNotEmpty) ...[
                          const SizedBox(height: AppConstants.spacingElement),
                          _ErrorCodeChip(message: errorMessage),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _RetryButton(onRetry: () => _retryConversion(context)),
              const SizedBox(height: AppConstants.spacingSmall + 4),
              _SelectAnotherButton(
                onSelect: () => _selectAnotherVideo(context),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
              const BannerAdWidget(),
              const SizedBox(height: AppConstants.spacingElement),
            ],
          ),
        ),
      ),
    );
  }

  /// Retries the conversion with the same settings.
  void _retryConversion(BuildContext context) {
    final provider = context.read<ConversionProvider>();
    provider.startConversion();
    Navigator.of(context).pop(); // Back to converting screen.
  }

  /// Resets and goes back to home to pick a new video.
  void _selectAnotherVideo(BuildContext context) {
    _navigateHome(context);
  }

  /// Resets state and pops to the home screen.
  void _navigateHome(BuildContext context) {
    context.read<ConversionProvider>().reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ─── Error Illustration ───────────────────────────────────────────────

/// Broken-disc icon stack: a large album/disc icon with a red error
/// badge overlaid at the bottom-right.
class _ErrorIllustration extends StatelessWidget {
  const _ErrorIllustration();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Branded audio disc icon.
          AudioIcon(
            size: 140,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),

          // Red error badge.
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Heading ────────────────────────────────────────────────────

/// "Something went wrong" title.
class _ErrorHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.somethingWentWrong,
      style: Theme.of(context).textTheme.displayLarge,
      textAlign: TextAlign.center,
    );
  }
}

// ─── Error Description ────────────────────────────────────────────────

/// Multi-line explanatory paragraph below the heading.
class _ErrorDescription extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.errorDescription,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }
}

// ─── Error Code Chip ──────────────────────────────────────────────────

/// Red-tinted rounded chip displaying the raw error message.
class _ErrorCodeChip extends StatelessWidget {
  const _ErrorCodeChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingElement,
        vertical: AppConstants.spacingSmall + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Retry Button ─────────────────────────────────────────────────────

/// Full-width primary "↻ Retry Conversion" button.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(AppStrings.retryConversion),
      ),
    );
  }
}

// ─── Select Another Video Button ──────────────────────────────────────

/// Full-width dark/outlined "Select Another Video" button.
class _SelectAnotherButton extends StatelessWidget {
  const _SelectAnotherButton({required this.onSelect});

  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onSelect,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
          minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
        ),
        child: const Text(AppStrings.selectAnotherVideo),
      ),
    );
  }
}
