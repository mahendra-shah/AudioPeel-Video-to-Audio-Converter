import 'audio_quality.dart';
import 'output_format.dart';

/// A completed conversion record stored in the database.
///
/// Immutable — use [copyWith] for updates and [toMap] / [fromMap] for SQLite.
class AudioFile {
  const AudioFile({
    this.id,
    required this.inputVideoName,
    required this.inputVideoPath,
    required this.outputAudioName,
    required this.outputAudioPath,
    required this.quality,
    required this.fileSize,
    required this.duration,
    required this.status,
    required this.createdAt,
    this.errorMessage,
    this.format = OutputFormat.mp3,
    this.displayPath,
  });

  /// Auto-incremented database primary key. `null` before insertion.
  final int? id;

  /// Original video file name (e.g. "vacation.mp4").
  final String inputVideoName;

  /// Source video URI (`content://`) or legacy file path.
  final String inputVideoPath;

  /// Generated MP3 file name (e.g. "vacation_audio.mp3").
  final String outputAudioName;

  /// Output location: a MediaStore `content://` URI (v2) or a legacy file
  /// path (v1, app-private storage).
  final String outputAudioPath;

  /// The bitrate used for this conversion.
  final AudioQuality quality;

  /// Output file size in bytes.
  final int fileSize;

  /// Audio duration in seconds.
  final int duration;

  /// Either `"completed"` or `"failed"`.
  final String status;

  /// When this conversion was created.
  final DateTime createdAt;

  /// Error text if [status] is `"failed"`, otherwise `null`.
  final String? errorMessage;

  /// Container of the output audio.
  final OutputFormat format;

  /// Human-readable location, e.g. "Music/AudioPeel/song.mp3".
  final String? displayPath;

  /// Whether this conversion was successful.
  bool get isCompleted => status == 'completed';

  /// Whether the output lives in MediaStore (shareable without a path).
  bool get isContentUri => outputAudioPath.startsWith('content://');

  /// Short quality badge, e.g. "320k" or "FLAC".
  String get qualityBadge =>
      format.lossless ? format.label : '${format.label} · ${quality.kbps}k';

  // ─── SQLite Serialisation ───────────────────────────────────────────

  /// Converts this instance to a [Map] suitable for SQLite insertion.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'input_video_name': inputVideoName,
      'input_video_path': inputVideoPath,
      'output_audio_name': outputAudioName,
      'output_audio_path': outputAudioPath,
      'quality': quality.kbps,
      'file_size': fileSize,
      'duration': duration,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'error_message': errorMessage,
      'format': format.name,
      'display_path': displayPath,
    };
  }

  /// Creates an [AudioFile] from a SQLite row.
  factory AudioFile.fromMap(Map<String, Object?> map) {
    return AudioFile(
      id: map['id'] as int?,
      inputVideoName: map['input_video_name'] as String,
      inputVideoPath: map['input_video_path'] as String,
      outputAudioName: map['output_audio_name'] as String,
      outputAudioPath: map['output_audio_path'] as String,
      quality: AudioQuality.fromKbps(map['quality'] as int),
      fileSize: map['file_size'] as int,
      duration: map['duration'] as int,
      status: map['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      errorMessage: map['error_message'] as String?,
      format: map['format'] != null
          ? OutputFormat.fromName(map['format'] as String?)
          : OutputFormat.fromFileName(map['output_audio_name'] as String),
      displayPath: map['display_path'] as String?,
    );
  }

  /// Creates a copy with the given fields replaced.
  AudioFile copyWith({
    int? id,
    String? inputVideoName,
    String? inputVideoPath,
    String? outputAudioName,
    String? outputAudioPath,
    AudioQuality? quality,
    int? fileSize,
    int? duration,
    String? status,
    DateTime? createdAt,
    String? errorMessage,
    OutputFormat? format,
    String? displayPath,
  }) {
    return AudioFile(
      id: id ?? this.id,
      inputVideoName: inputVideoName ?? this.inputVideoName,
      inputVideoPath: inputVideoPath ?? this.inputVideoPath,
      outputAudioName: outputAudioName ?? this.outputAudioName,
      outputAudioPath: outputAudioPath ?? this.outputAudioPath,
      quality: quality ?? this.quality,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      format: format ?? this.format,
      displayPath: displayPath ?? this.displayPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioFile &&
        other.id == id &&
        other.outputAudioPath == outputAudioPath;
  }

  @override
  int get hashCode => Object.hash(id, outputAudioPath);

  @override
  String toString() =>
      'AudioFile(id: $id, name: $outputAudioName, '
      'quality: ${quality.kbps}kbps, status: $status)';
}
