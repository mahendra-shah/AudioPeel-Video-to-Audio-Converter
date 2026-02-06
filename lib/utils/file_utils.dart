import 'dart:io';

import 'package:path/path.dart' as p;

/// File-system helpers — extension checks, name generation, etc.
abstract final class FileUtils {
  /// Returns `true` if [path] points to a supported video file.
  static bool isSupportedVideo(String path) {
    final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
    const supported = {
      'mp4',
      'mkv',
      'avi',
      'mov',
      'wmv',
      'flv',
      'webm',
      '3gp',
      'ts',
      'm4v',
    };
    return supported.contains(ext);
  }

  /// Derives a default output name from the video file name.
  ///
  /// Example: `vacation_clip.mp4` → `vacation_clip_audio`.
  static String defaultOutputName(String videoPath) {
    final baseName = p.basenameWithoutExtension(videoPath);
    return '${baseName}_audio';
  }

  /// Returns a unique file path so we never overwrite an existing file.
  ///
  /// Appends `(1)`, `(2)`, … if the name already exists.
  static String uniquePath(String directory, String name, String extension) {
    var candidate = p.join(directory, '$name.$extension');
    var counter = 1;
    while (File(candidate).existsSync()) {
      candidate = p.join(directory, '$name ($counter).$extension');
      counter++;
    }
    return candidate;
  }

  /// Gets the file size in bytes, returning `0` if the file doesn't exist.
  static int fileSize(String path) {
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  /// Deletes a file if it exists. Silently ignores missing files.
  static Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
