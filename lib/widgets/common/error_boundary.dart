import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../utils/logger.dart';

/// Catches build errors in [child] and shows a friendly fallback instead
/// of crashing the entire app.
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: SomeFragileWidget(),
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  /// Creates an error boundary around [child].
  const ErrorBoundary({required this.child, this.onError, super.key});

  /// The widget subtree to protect.
  final Widget child;

  /// Optional callback invoked with the caught error and stack trace.
  final void Function(FlutterErrorDetails details)? onError;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // Override the default error handler so this boundary can catch
    // errors that occur during the build phase of its subtree.
    FlutterError.onError = (details) {
      Logger.error(
        'ErrorBoundary caught: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
        tag: 'ErrorBoundary',
      );
      widget.onError?.call(details);
      if (mounted) {
        setState(() => _error = details);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallback(
        message: _error!.exceptionAsString(),
        onRetry: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }
}

/// A minimal fallback widget shown when [ErrorBoundary] catches an error.
class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingScreen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppConstants.spacingElement),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.spacingElement),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
