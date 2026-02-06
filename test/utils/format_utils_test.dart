import 'package:flutter_test/flutter_test.dart';
import 'package:mp3_extract/utils/format_utils.dart';

void main() {
  group('FormatUtils.fileSize', () {
    test('formats bytes', () {
      expect(FormatUtils.fileSize(512), '512 B');
    });

    test('formats kilobytes', () {
      expect(FormatUtils.fileSize(1024), '1.0 KB');
      expect(FormatUtils.fileSize(1536), '1.5 KB');
    });

    test('formats megabytes', () {
      expect(FormatUtils.fileSize(1048576), '1.0 MB');
      expect(FormatUtils.fileSize(3670016), '3.5 MB');
    });

    test('formats gigabytes', () {
      expect(FormatUtils.fileSize(1073741824), '1.0 GB');
    });

    test('handles zero', () {
      expect(FormatUtils.fileSize(0), '0 B');
    });
  });

  group('FormatUtils.duration', () {
    test('formats seconds under a minute', () {
      expect(FormatUtils.duration(5), '00:05');
      expect(FormatUtils.duration(45), '00:45');
    });

    test('formats minutes and seconds', () {
      expect(FormatUtils.duration(65), '01:05');
      expect(FormatUtils.duration(600), '10:00');
    });

    test('formats hours', () {
      expect(FormatUtils.duration(3661), '1:01:01');
      expect(FormatUtils.duration(7200), '2:00:00');
    });

    test('handles zero', () {
      expect(FormatUtils.duration(0), '00:00');
    });
  });

  group('FormatUtils.durationFromMs', () {
    test('converts milliseconds to duration string', () {
      expect(FormatUtils.durationFromMs(180000), '03:00');
      expect(FormatUtils.durationFromMs(65000), '01:05');
    });

    test('truncates sub-second remainder', () {
      expect(FormatUtils.durationFromMs(5999), '00:05');
    });
  });

  group('FormatUtils.relativeDate', () {
    test('formats today', () {
      final now = DateTime.now();
      final result = FormatUtils.relativeDate(now);
      expect(result, startsWith('Today'));
    });

    test('formats yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = FormatUtils.relativeDate(yesterday);
      expect(result, startsWith('Yesterday'));
    });

    test('formats dates older than a week with month', () {
      final old = DateTime.now().subtract(const Duration(days: 30));
      final result = FormatUtils.relativeDate(old);
      // Should contain the month abbreviation, not "Today"/"Yesterday".
      expect(result.startsWith('Today'), isFalse);
      expect(result.startsWith('Yesterday'), isFalse);
    });
  });

  group('FormatUtils.estimateFileSize', () {
    test('estimates correctly for 192kbps, 180 seconds', () {
      // 180 * 192 * 1000 / 8 = 4_320_000 bytes
      expect(FormatUtils.estimateFileSize(180, 192), 4320000);
    });

    test('returns 0 for zero duration', () {
      expect(FormatUtils.estimateFileSize(0, 320), 0);
    });
  });

  group('FormatUtils.estimateConversionTime', () {
    test('returns at least 1 second', () {
      expect(FormatUtils.estimateConversionTime(1), greaterThanOrEqualTo(1));
      expect(FormatUtils.estimateConversionTime(0), 1);
    });

    test('divides by ~10 for realistic estimate', () {
      // 300s video → ~30s conversion
      expect(FormatUtils.estimateConversionTime(300), 30);
    });
  });

  group('FormatUtils.sanitizeFileName', () {
    test('strips illegal characters', () {
      expect(FormatUtils.sanitizeFileName('my<file>name'), 'my_file_name');
      expect(FormatUtils.sanitizeFileName('file:name'), 'file_name');
      expect(FormatUtils.sanitizeFileName('file|name'), 'file_name');
    });

    test('trims whitespace', () {
      expect(FormatUtils.sanitizeFileName('  hello  '), 'hello');
    });

    test('returns empty string when all chars are illegal', () {
      expect(FormatUtils.sanitizeFileName('  '), '');
    });

    test('passes through clean names unchanged', () {
      expect(FormatUtils.sanitizeFileName('good_file-name'), 'good_file-name');
    });
  });
}
