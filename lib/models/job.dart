import 'convert_options.dart';
import 'media_item.dart';
import 'output_format.dart';

enum JobStatus { queued, running, done, failed, cancelled }

/// A saved audio file in the user's library.
class SavedAudio {
  const SavedAudio({
    required this.uri,
    required this.name,
    required this.displayPath,
    required this.sizeBytes,
    required this.durationMs,
    required this.format,
  });

  /// `content://` MediaStore URI (or a file path for legacy records).
  final String uri;
  final String name;

  /// Human path, e.g. "Music/AudioPeel/song.mp3".
  final String displayPath;
  final int sizeBytes;
  final int durationMs;
  final OutputFormat format;
}

/// One conversion in the queue. Mutated only by the queue provider, which
/// notifies listeners after every change.
class Job {
  Job({required this.id, required this.media, required this.options});

  final int id;
  final MediaItem media;
  final ConvertOptions options;

  JobStatus status = JobStatus.queued;

  /// 0.0 – 1.0 as reported by FFmpeg.
  double progress = 0;

  DateTime? startedAt;
  DateTime? finishedAt;
  SavedAudio? result;
  String? error;

  /// FFmpeg session id while running (for cancellation).
  int? sessionId;

  bool get isFinished =>
      status == JobStatus.done ||
      status == JobStatus.failed ||
      status == JobStatus.cancelled;

  /// Output name with extension, e.g. "Summer Vibes.mp3".
  String get outputName {
    final base = options.fileName.trim().isEmpty
        ? media.baseName
        : options.fileName.trim();
    return '$base.${options.format.extension}';
  }

  /// Remaining time from real elapsed time, or `null` until measurable.
  Duration? get eta {
    final start = startedAt;
    if (start == null || progress < 0.03 || progress >= 1) return null;
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final remaining = elapsed / progress - elapsed;
    return Duration(milliseconds: remaining.round().clamp(0, 1 << 31));
  }
}
