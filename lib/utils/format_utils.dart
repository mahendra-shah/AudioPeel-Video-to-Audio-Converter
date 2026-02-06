import 'package:intl/intl.dart';

/// Formatting helpers for duration, file size, dates, etc.
abstract final class FormatUtils {
  /// Formats [bytes] into a human-readable string (e.g. "3.2 MB").
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Formats [seconds] as `mm:ss` or `h:mm:ss` if over an hour.
  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  /// Formats [milliseconds] as `mm:ss` or `h:mm:ss`.
  static String durationFromMs(int milliseconds) =>
      duration(milliseconds ~/ 1000);

  /// Formats a [DateTime] for the history list (e.g. "Today, 3:45 PM").
  static String relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat.jm().format(dateTime);

    if (target == today) return 'Today, $timeStr';

    final yesterday = today.subtract(const Duration(days: 1));
    if (target == yesterday) return 'Yesterday, $timeStr';

    if (now.difference(dateTime).inDays < 7) {
      return '${DateFormat.EEEE().format(dateTime)}, $timeStr';
    }
    return DateFormat.yMMMd().format(dateTime);
  }

  /// Estimates the output file size in bytes given [durationSeconds] and
  /// [bitrateKbps] (e.g. 192).
  static int estimateFileSize(int durationSeconds, int bitrateKbps) =>
      (durationSeconds * bitrateKbps * 1000) ~/ 8;

  /// Rough estimate of conversion time in seconds given video duration.
  ///
  /// Modern devices process ~10-20× real-time via FFmpeg hardware decode.
  static int estimateConversionTime(int videoDurationSeconds) {
    // Conservative: ~10× real-time speed.
    final estimate = (videoDurationSeconds / 10).ceil();
    return estimate < 1 ? 1 : estimate;
  }

  /// Sanitises a user-entered file name by stripping illegal characters.
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
