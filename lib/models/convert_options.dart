import 'audio_quality.dart';
import 'media_item.dart';
import 'output_format.dart';

/// Everything the Studio lets the user shape before converting.
class ConvertOptions {
  const ConvertOptions({
    this.format = OutputFormat.mp3,
    this.quality = AudioQuality.medium192,
    this.trimStartMs = 0,
    this.trimEndMs,
    this.normalize = false,
    this.volume = 1.0,
    this.fadeIn = false,
    this.fadeOut = false,
    this.albumArt = true,
    this.title = '',
    this.artist = '',
    this.fileName = '',
  });

  final OutputFormat format;
  final AudioQuality quality;

  /// Trim start in ms (0 = from the beginning).
  final int trimStartMs;

  /// Trim end in ms, or `null` for "until the end".
  final int? trimEndMs;

  final bool normalize;

  /// Linear gain, 1.0 = unchanged, up to 2.0 (+6 dB).
  final double volume;

  final bool fadeIn;
  final bool fadeOut;

  /// Embed a video frame as cover art (MP3 only).
  final bool albumArt;

  final String title;
  final String artist;

  /// Output file name without extension. Empty = derive from the video.
  final String fileName;

  /// Fade length in seconds.
  static const double fadeSeconds = 1.5;

  bool isTrimmed(MediaItem media) =>
      trimStartMs > 0 || (trimEndMs != null && trimEndMs! < media.durationMs);

  int effectiveEndMs(MediaItem media) =>
      (trimEndMs ?? media.durationMs).clamp(0, media.durationMs);

  /// Length of the exported audio.
  int outputDurationMs(MediaItem media) =>
      (effectiveEndMs(media) - trimStartMs).clamp(0, media.durationMs);

  bool get hasFilters => normalize || volume != 1.0 || fadeIn || fadeOut;

  bool get hasTags => title.trim().isNotEmpty || artist.trim().isNotEmpty;

  /// M4A from an AAC source with no filters can be stream-copied: instant
  /// and lossless.
  bool canStreamCopy(MediaItem media) =>
      format == OutputFormat.m4a && media.isAac && !hasFilters;

  /// Whether album art will actually be embedded.
  bool embedsArt(MediaItem media) =>
      albumArt && format == OutputFormat.mp3 && media.hasVideo;

  /// Rough output size so the CTA can show "≈ 3.2 MB".
  int estimatedBytes(MediaItem media) {
    final seconds = outputDurationMs(media) / 1000;
    switch (format) {
      case OutputFormat.wav:
        return (seconds * 44100 * 2 * 2).round();
      case OutputFormat.flac:
        return (seconds * 44100 * 2 * 2 * 0.6).round();
      case OutputFormat.m4a:
        if (canStreamCopy(media) && media.bitrate > 0) {
          return (seconds * media.bitrate / 8).round();
        }
        return (seconds * quality.kbps * 1000 / 8).round();
      case OutputFormat.mp3:
        return (seconds * quality.kbps * 1000 / 8).round();
    }
  }

  ConvertOptions copyWith({
    OutputFormat? format,
    AudioQuality? quality,
    int? trimStartMs,
    int? Function()? trimEndMs,
    bool? normalize,
    double? volume,
    bool? fadeIn,
    bool? fadeOut,
    bool? albumArt,
    String? title,
    String? artist,
    String? fileName,
  }) {
    return ConvertOptions(
      format: format ?? this.format,
      quality: quality ?? this.quality,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs != null ? trimEndMs() : this.trimEndMs,
      normalize: normalize ?? this.normalize,
      volume: volume ?? this.volume,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
      albumArt: albumArt ?? this.albumArt,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      fileName: fileName ?? this.fileName,
    );
  }
}
