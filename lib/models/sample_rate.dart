/// Supported audio sample rates.
enum SampleRate {
  sr32000(32000, '32 kHz'),
  sr44100(44100, '44.1 kHz'),
  sr48000(48000, '48 kHz'),
  sr96000(96000, '96 kHz'),
  sr192000(192000, '192 kHz');

  const SampleRate(this.hz, this.displayName);

  /// Sample rate in Hertz.
  final int hz;

  /// Human-readable label (e.g. "44.1 kHz").
  final String displayName;

  /// Returns the [SampleRate] matching [hz], or [sr44100] as fallback.
  static SampleRate fromHz(int hz) {
    return SampleRate.values.firstWhere(
      (s) => s.hz == hz,
      orElse: () => SampleRate.sr44100,
    );
  }
}
