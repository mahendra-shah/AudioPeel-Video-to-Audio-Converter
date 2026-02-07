/// Supported audio channel configurations.
enum AudioChannel {
  mono(1, 'Mono'),
  stereo(2, 'Stereo');

  const AudioChannel(this.count, this.displayName);

  /// Number of channels.
  final int count;

  /// Human-readable label (e.g. "Stereo").
  final String displayName;

  /// Returns the [AudioChannel] matching [count], or [stereo] as fallback.
  static AudioChannel fromCount(int count) {
    return AudioChannel.values.firstWhere(
      (c) => c.count == count,
      orElse: () => AudioChannel.stereo,
    );
  }
}
