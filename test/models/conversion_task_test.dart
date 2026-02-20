import 'package:flutter_test/flutter_test.dart';
import 'package:audiopeel/models/audio_quality.dart';
import 'package:audiopeel/models/conversion_task.dart';

void main() {
  group('ConversionStatus', () {
    test('has five values', () {
      expect(ConversionStatus.values.length, 5);
    });
  });

  group('ConversionTask', () {
    ConversionTask sampleTask({
      ConversionStatus status = ConversionStatus.idle,
      double progress = 0.0,
      String? errorMessage,
    }) {
      return ConversionTask(
        inputVideoPath: '/videos/clip.mp4',
        inputVideoName: 'clip.mp4',
        outputAudioPath: '/mp3/clip_audio.mp3',
        outputAudioName: 'clip_audio.mp3',
        quality: AudioQuality.high320,
        status: status,
        progress: progress,
        videoDurationMs: 60000,
        errorMessage: errorMessage,
      );
    }

    test('defaults are correct', () {
      final task = sampleTask();
      expect(task.status, ConversionStatus.idle);
      expect(task.progress, 0.0);
      expect(task.errorMessage, isNull);
      expect(task.isActive, isFalse);
    });

    test('isActive returns true only when converting', () {
      expect(sampleTask(status: ConversionStatus.converting).isActive, isTrue);
      expect(sampleTask(status: ConversionStatus.completed).isActive, isFalse);
      expect(sampleTask(status: ConversionStatus.failed).isActive, isFalse);
      expect(sampleTask(status: ConversionStatus.cancelled).isActive, isFalse);
    });

    test('copyWith replaces specified fields', () {
      final original = sampleTask();
      final updated = original.copyWith(
        status: ConversionStatus.completed,
        progress: 1.0,
      );

      expect(updated.status, ConversionStatus.completed);
      expect(updated.progress, 1.0);
      // Unchanged.
      expect(updated.inputVideoPath, original.inputVideoPath);
      expect(updated.quality, original.quality);
      expect(updated.videoDurationMs, original.videoDurationMs);
    });

    test('copyWith can set errorMessage', () {
      final task = sampleTask().copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'codec error',
      );
      expect(task.errorMessage, 'codec error');
    });

    test('equality compares key fields', () {
      final a = sampleTask(status: ConversionStatus.converting, progress: 0.5);
      final b = sampleTask(status: ConversionStatus.converting, progress: 0.5);
      final c = sampleTask(status: ConversionStatus.completed, progress: 1.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = sampleTask(status: ConversionStatus.converting, progress: 0.5);
      final b = sampleTask(status: ConversionStatus.converting, progress: 0.5);
      expect(a.hashCode, b.hashCode);
    });

    test('toString contains useful info', () {
      final task = sampleTask(
        status: ConversionStatus.converting,
        progress: 0.456,
      );
      final str = task.toString();
      expect(str, contains('clip.mp4'));
      expect(str, contains('converting'));
      expect(str, contains('45.6%'));
    });
  });
}
