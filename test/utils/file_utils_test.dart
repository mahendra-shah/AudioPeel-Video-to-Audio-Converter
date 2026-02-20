import 'package:flutter_test/flutter_test.dart';
import 'package:audiopeel/utils/file_utils.dart';

void main() {
  group('FileUtils.isSupportedVideo', () {
    test('accepts common video extensions', () {
      expect(FileUtils.isSupportedVideo('/path/to/video.mp4'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.mkv'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.avi'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.mov'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.wmv'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.flv'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.webm'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.3gp'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.ts'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/to/video.m4v'), isTrue);
    });

    test('is case-insensitive', () {
      expect(FileUtils.isSupportedVideo('/path/VIDEO.MP4'), isTrue);
      expect(FileUtils.isSupportedVideo('/path/Movie.MKV'), isTrue);
    });

    test('rejects non-video extensions', () {
      expect(FileUtils.isSupportedVideo('/path/to/image.png'), isFalse);
      expect(FileUtils.isSupportedVideo('/path/to/audio.mp3'), isFalse);
      expect(FileUtils.isSupportedVideo('/path/to/doc.pdf'), isFalse);
    });

    test('rejects files with no extension', () {
      expect(FileUtils.isSupportedVideo('/path/to/noext'), isFalse);
    });
  });

  group('FileUtils.defaultOutputName', () {
    test('strips extension and appends _audio', () {
      expect(
        FileUtils.defaultOutputName('/videos/vacation.mp4'),
        'vacation_audio',
      );
    });

    test('handles paths with multiple dots', () {
      expect(
        FileUtils.defaultOutputName('/videos/my.video.file.mkv'),
        'my.video.file_audio',
      );
    });

    test('handles simple file names', () {
      expect(FileUtils.defaultOutputName('clip.avi'), 'clip_audio');
    });
  });
}
