import 'package:flutter_test/flutter_test.dart';
import 'package:mp3_extract/models/audio_quality.dart';
import 'package:mp3_extract/providers/conversion_provider.dart';

/// Validates public API of [ConversionProvider] that does not require
/// file-system or FFmpeg access.  Full conversion-flow tests belong in
/// integration tests.
void main() {
  group('ConversionProvider — unit', () {
    late ConversionProvider provider;

    setUp(() {
      provider = ConversionProvider();
    });

    test('initial state is clean', () {
      expect(provider.task, isNull);
      expect(provider.selectedVideo, isNull);
      expect(provider.outputName, isEmpty);
      expect(provider.quality, AudioQuality.medium192);
      expect(provider.videoDurationMs, 0);
      expect(provider.videoSizeBytes, 0);
      expect(provider.isConverting, isFalse);
      expect(provider.progress, 0.0);
      expect(provider.error, isNull);
      expect(provider.isReadyToConvert, isFalse);
    });

    test('updateOutputName updates the name and notifies', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.updateOutputName('my_song');

      expect(provider.outputName, 'my_song');
      expect(notified, isTrue);
    });

    test('selectQuality updates quality and notifies', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.selectQuality(AudioQuality.high320);

      expect(provider.quality, AudioQuality.high320);
      expect(notified, isTrue);
    });

    test('reset clears all state', () {
      provider.updateOutputName('something');
      provider.selectQuality(AudioQuality.high320);

      provider.reset();

      expect(provider.task, isNull);
      expect(provider.selectedVideo, isNull);
      expect(provider.outputName, isEmpty);
      expect(provider.videoDurationMs, 0);
      expect(provider.videoSizeBytes, 0);
    });

    test('startConversion does nothing when no video selected', () async {
      // Should silently return without crashing.
      await provider.startConversion();
      expect(provider.task, isNull);
    });

    test('startConversion does nothing when output name is empty', () async {
      // No video selected + empty name — should be a no-op.
      provider.updateOutputName('');
      await provider.startConversion();
      expect(provider.task, isNull);
    });

    test('isConverting reflects task status', () {
      // We can't easily set _task from outside, so we verify the getter
      // logic indirectly: when task is null, isConverting is false.
      expect(provider.isConverting, isFalse);
    });

    test('isReadyToConvert requires both video and name', () {
      // No video, no name.
      expect(provider.isReadyToConvert, isFalse);

      // Name only — still false because video is null.
      provider.updateOutputName('test');
      expect(provider.isReadyToConvert, isFalse);
    });

    test('dispose does not throw', () {
      expect(() => provider.dispose(), returnsNormally);
    });
  });
}
