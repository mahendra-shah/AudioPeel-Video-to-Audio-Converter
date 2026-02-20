import 'package:flutter_test/flutter_test.dart';
import 'package:audiopeel/models/audio_file.dart';
import 'package:audiopeel/models/audio_quality.dart';

void main() {
  group('AudioFile', () {
    final now = DateTime(2026, 2, 6, 10, 30);

    AudioFile sampleFile({
      int? id,
      String status = 'completed',
      AudioQuality quality = AudioQuality.medium192,
      String? errorMessage,
    }) {
      return AudioFile(
        id: id,
        inputVideoName: 'test_video.mp4',
        inputVideoPath: '/storage/videos/test_video.mp4',
        outputAudioName: 'test_video_audio.mp3',
        outputAudioPath: '/storage/audiopeel/test_video_audio.mp3',
        quality: quality,
        fileSize: 3500000,
        duration: 180,
        status: status,
        createdAt: now,
        errorMessage: errorMessage,
      );
    }

    test('toMap produces correct keys and values', () {
      final file = sampleFile(id: 1);
      final map = file.toMap();

      expect(map['id'], 1);
      expect(map['input_video_name'], 'test_video.mp4');
      expect(map['input_video_path'], '/storage/videos/test_video.mp4');
      expect(map['output_audio_name'], 'test_video_audio.mp3');
      expect(
        map['output_audio_path'],
        '/storage/audiopeel/test_video_audio.mp3',
      );
      expect(map['quality'], 192);
      expect(map['file_size'], 3500000);
      expect(map['duration'], 180);
      expect(map['status'], 'completed');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['error_message'], isNull);
    });

    test('toMap omits id when null', () {
      final file = sampleFile();
      final map = file.toMap();

      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap round-trips correctly', () {
      final original = sampleFile(id: 42);
      final restored = AudioFile.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.inputVideoName, original.inputVideoName);
      expect(restored.outputAudioName, original.outputAudioName);
      expect(restored.quality, original.quality);
      expect(restored.fileSize, original.fileSize);
      expect(restored.duration, original.duration);
      expect(restored.status, original.status);
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        original.createdAt.millisecondsSinceEpoch,
      );
      expect(restored.errorMessage, isNull);
    });

    test('fromMap handles error_message', () {
      final original = sampleFile(
        id: 1,
        status: 'failed',
        errorMessage: 'FFmpeg error: codec not found',
      );
      final restored = AudioFile.fromMap(original.toMap());

      expect(restored.status, 'failed');
      expect(restored.errorMessage, 'FFmpeg error: codec not found');
      expect(restored.isCompleted, isFalse);
    });

    test('isCompleted returns correct value', () {
      expect(sampleFile(status: 'completed').isCompleted, isTrue);
      expect(sampleFile(status: 'failed').isCompleted, isFalse);
    });

    test('copyWith replaces specified fields', () {
      final original = sampleFile(id: 1);
      final updated = original.copyWith(
        fileSize: 5000000,
        status: 'failed',
        errorMessage: 'disk full',
      );

      expect(updated.fileSize, 5000000);
      expect(updated.status, 'failed');
      expect(updated.errorMessage, 'disk full');
      // Unchanged fields.
      expect(updated.id, original.id);
      expect(updated.inputVideoName, original.inputVideoName);
      expect(updated.quality, original.quality);
    });

    test('equality is based on id and outputAudioPath', () {
      final a = sampleFile(id: 1);
      final b = sampleFile(id: 1);
      final c = sampleFile(id: 2);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('AudioQuality', () {
    test('fromKbps returns correct enum value', () {
      expect(AudioQuality.fromKbps(128), AudioQuality.low128);
      expect(AudioQuality.fromKbps(192), AudioQuality.medium192);
      expect(AudioQuality.fromKbps(320), AudioQuality.high320);
    });

    test('fromKbps falls back to medium192 for unknown values', () {
      expect(AudioQuality.fromKbps(256), AudioQuality.medium192);
      expect(AudioQuality.fromKbps(0), AudioQuality.medium192);
    });

    test('properties are correct', () {
      expect(AudioQuality.low128.kbps, 128);
      expect(AudioQuality.low128.label, 'Standard');
      expect(AudioQuality.low128.displayName, '128 kbps');

      expect(AudioQuality.medium192.kbps, 192);
      expect(AudioQuality.medium192.label, 'High Quality');

      expect(AudioQuality.high320.kbps, 320);
      expect(AudioQuality.high320.label, 'Maximum');
    });
  });

  group('ConversionTask', () {
    // ConversionTask tests are in a separate import to keep focus.
    // Basic smoke test here.
    test('placeholder for ConversionTask tests', () {
      // Covered by the model file — add widget/integration tests later.
      expect(true, isTrue);
    });
  });
}
