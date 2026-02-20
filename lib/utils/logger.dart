import 'dart:developer' as dev;

/// Lightweight logging wrapper.
///
/// Uses `dart:developer` log so messages appear in the debug console
/// without triggering the `avoid_print` lint.
abstract final class Logger {
  static const String _tag = 'AudioPeel';

  /// Logs a debug-level message.
  static void debug(String message, [String? tag]) {
    dev.log(message, name: tag ?? _tag, level: 500);
  }

  /// Logs an info-level message.
  static void info(String message, [String? tag]) {
    dev.log(message, name: tag ?? _tag, level: 800);
  }

  /// Logs a warning-level message.
  static void warning(String message, [String? tag]) {
    dev.log(message, name: tag ?? _tag, level: 900);
  }

  /// Logs an error with optional [error] object and [stackTrace].
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    dev.log(
      message,
      name: tag ?? _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
