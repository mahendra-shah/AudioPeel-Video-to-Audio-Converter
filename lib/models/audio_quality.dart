/// Supported audio bitrates for MP3 conversion.
enum AudioQuality {
  /// 128 kbps — Standard quality, smallest file size.
  low128(128, 'Standard', '128 kbps'),

  /// 192 kbps — Recommended balance of size and quality.
  medium192(192, 'High Quality', '192 kbps'),

  /// 320 kbps — Maximum quality, largest file size.
  high320(320, 'Maximum', '320 kbps');

  const AudioQuality(this.kbps, this.label, this.displayName);

  /// Bitrate in kilobits per second.
  final int kbps;

  /// Human-readable label (e.g. "High Quality").
  final String label;

  /// Short display name shown in chips (e.g. "192 kbps").
  final String displayName;

  /// Returns the [AudioQuality] matching [kbps], or [medium192] as fallback.
  static AudioQuality fromKbps(int kbps) {
    return AudioQuality.values.firstWhere(
      (q) => q.kbps == kbps,
      orElse: () => AudioQuality.medium192,
    );
  }
}
