import 'audio_quality.dart';

/// The current status of a conversion operation.
enum ConversionStatus {
  /// Waiting for user to start.
  idle,

  /// Conversion is running.
  converting,

  /// Conversion completed successfully.
  completed,

  /// Conversion failed.
  failed,

  /// User cancelled the conversion.
  cancelled,
}

/// Represents an in-flight (or recently finished) conversion.
///
/// This is an immutable value object — create a new instance via [copyWith]
/// when state changes.
class ConversionTask {
  const ConversionTask({
    required this.inputVideoPath,
    required this.inputVideoName,
    required this.outputAudioPath,
    required this.outputAudioName,
    required this.quality,
    this.status = ConversionStatus.idle,
    this.progress = 0.0,
    this.videoDurationMs = 0,
    this.errorMessage,
  });

  /// Full path to the source video file.
  final String inputVideoPath;

  /// Display name of the source video (e.g. "my_video.mp4").
  final String inputVideoName;

  /// Full path where the output MP3 will be written.
  final String outputAudioPath;

  /// Display name of the output file (e.g. "my_video_audio.mp3").
  final String outputAudioName;

  /// The selected bitrate for this conversion.
  final AudioQuality quality;

  /// Current status.
  final ConversionStatus status;

  /// Progress from `0.0` to `1.0`.
  final double progress;

  /// Total video duration in milliseconds (used for progress calculation).
  final int videoDurationMs;

  /// Error description if [status] is [ConversionStatus.failed].
  final String? errorMessage;

  /// Whether the task is currently processing.
  bool get isActive => status == ConversionStatus.converting;

  /// Creates a copy with the given fields replaced.
  ConversionTask copyWith({
    String? inputVideoPath,
    String? inputVideoName,
    String? outputAudioPath,
    String? outputAudioName,
    AudioQuality? quality,
    ConversionStatus? status,
    double? progress,
    int? videoDurationMs,
    String? errorMessage,
  }) {
    return ConversionTask(
      inputVideoPath: inputVideoPath ?? this.inputVideoPath,
      inputVideoName: inputVideoName ?? this.inputVideoName,
      outputAudioPath: outputAudioPath ?? this.outputAudioPath,
      outputAudioName: outputAudioName ?? this.outputAudioName,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversionTask &&
        other.inputVideoPath == inputVideoPath &&
        other.outputAudioPath == outputAudioPath &&
        other.quality == quality &&
        other.status == status &&
        other.progress == progress;
  }

  @override
  int get hashCode =>
      Object.hash(inputVideoPath, outputAudioPath, quality, status, progress);

  @override
  String toString() =>
      'ConversionTask(input: $inputVideoName, status: $status, '
      'progress: ${(progress * 100).toStringAsFixed(1)}%)';
}
