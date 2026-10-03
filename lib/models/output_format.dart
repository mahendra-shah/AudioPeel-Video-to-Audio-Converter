/// Audio containers the Studio can export.
enum OutputFormat {
  mp3('MP3', 'mp3', 'audio/mpeg', 'Plays everywhere', lossless: false),
  m4a('M4A', 'm4a', 'audio/mp4', 'Smaller, great quality', lossless: false),
  wav('WAV', 'wav', 'audio/wav', 'Uncompressed, for editing', lossless: true),
  flac('FLAC', 'flac', 'audio/flac', 'Lossless, compressed', lossless: true);

  const OutputFormat(
    this.label,
    this.extension,
    this.mime,
    this.blurb, {
    required this.lossless,
  });

  final String label;
  final String extension;
  final String mime;

  /// One-line description shown under the format picker.
  final String blurb;

  /// Lossless formats have no bitrate choice.
  final bool lossless;

  static OutputFormat fromName(String? name) => OutputFormat.values.firstWhere(
    (f) => f.name == name,
    orElse: () => OutputFormat.mp3,
  );

  /// Infers the format from a file name's extension.
  static OutputFormat fromFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return OutputFormat.values.firstWhere(
      (f) => f.extension == ext,
      orElse: () => OutputFormat.mp3,
    );
  }
}
