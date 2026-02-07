/// Supported audio output formats.
enum AudioFormat {
  mp3('MP3', 'mp3', 'audio/mpeg'),
  opus('OPUS', 'opus', 'audio/opus'),
  flac('FLAC', 'flac', 'audio/flac'),
  wav('WAV', 'wav', 'audio/wav'),
  ogg('OGG', 'ogg', 'audio/ogg'),
  m4a('M4A', 'm4a', 'audio/mp4'),
  wma('WMA', 'wma', 'audio/x-ms-wma'),
  aac('AAC', 'aac', 'audio/aac');

  const AudioFormat(this.displayName, this.extension, this.mimeType);

  /// Human-readable name (e.g. "MP3").
  final String displayName;

  /// File extension without dot (e.g. "mp3").
  final String extension;

  /// MIME type for sharing (e.g. "audio/mpeg").
  final String mimeType;

  /// Returns the [AudioFormat] matching [extension], or [mp3] as fallback.
  static AudioFormat fromExtension(String extension) {
    return AudioFormat.values.firstWhere(
      (f) => f.extension == extension.toLowerCase(),
      orElse: () => AudioFormat.mp3,
    );
  }
}
