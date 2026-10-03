import 'package:path/path.dart' as p;

/// A video the user picked or shared, described by the native probe.
///
/// [uri] is a `content://` URI (or a file path for legacy callers); the file
/// is never copied — FFmpeg reads it through SAF.
class MediaItem {
  const MediaItem({
    required this.uri,
    required this.name,
    required this.sizeBytes,
    required this.durationMs,
    this.mime,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.hasAudio = true,
    this.hasVideo = true,
    this.audioMime,
    this.sampleRate = 0,
    this.channels = 0,
    this.bitrate = 0,
  });

  factory MediaItem.fromMap(Map<Object?, Object?> m) {
    int asInt(Object? v) => v is num ? v.toInt() : 0;
    return MediaItem(
      uri: m['uri']! as String,
      name: (m['name'] as String?) ?? 'video',
      sizeBytes: asInt(m['size']),
      durationMs: asInt(m['durationMs']),
      mime: m['mime'] as String?,
      width: asInt(m['width']),
      height: asInt(m['height']),
      rotation: asInt(m['rotation']),
      hasAudio: m['hasAudio'] == true,
      hasVideo: m['hasVideo'] != false,
      audioMime: m['audioMime'] as String?,
      sampleRate: asInt(m['sampleRate']),
      channels: asInt(m['channels']),
      bitrate: asInt(m['bitrate']),
    );
  }

  final String uri;
  final String name;
  final int sizeBytes;
  final int durationMs;
  final String? mime;
  final int width;
  final int height;
  final int rotation;
  final bool hasAudio;
  final bool hasVideo;
  final String? audioMime;
  final int sampleRate;
  final int channels;
  final int bitrate;

  /// File name without its extension — the default output name.
  String get baseName {
    final base = p.basenameWithoutExtension(name).trim();
    return base.isEmpty ? 'audio' : base;
  }

  /// Whether the audio track is AAC, which allows an instant M4A stream copy.
  bool get isAac => audioMime == 'audio/mp4a-latm';

  /// Short human codec label, e.g. "AAC", "Opus".
  String get audioCodecLabel {
    switch (audioMime) {
      case 'audio/mp4a-latm':
        return 'AAC';
      case 'audio/mpeg':
        return 'MP3';
      case 'audio/opus':
        return 'Opus';
      case 'audio/vorbis':
        return 'Vorbis';
      case 'audio/ac3':
      case 'audio/eac3':
        return 'Dolby';
      case 'audio/flac':
        return 'FLAC';
      case 'audio/raw':
        return 'PCM';
      case null:
        return hasAudio ? 'Audio' : 'No audio';
      default:
        return audioMime!.replaceFirst('audio/', '').toUpperCase();
    }
  }

  /// Display aspect ratio, accounting for rotation.
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 16 / 9;
    final rotated = rotation == 90 || rotation == 270;
    return rotated ? height / width : width / height;
  }

  bool get isContentUri => uri.startsWith('content://');
}
