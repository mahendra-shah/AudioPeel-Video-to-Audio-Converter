import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/audio_channel.dart';
import '../models/audio_format.dart';
import '../models/sample_rate.dart';
import '../utils/logger.dart';

/// Manages user preferences such as theme mode and default quality.
///
/// Persists state via [SharedPreferences] so choices survive restarts.
class SettingsProvider extends ChangeNotifier {
  static const _tag = 'Settings';

  // Preference keys
  static const _prefNormalizeVolume = 'normalize_volume';
  static const _prefAutoDelete = 'auto_delete_original';
  static const _prefThemeMode = 'theme_mode';
  static const _prefAudioFormat = 'audio_format';
  static const _prefSampleRate = 'sample_rate';
  static const _prefAudioChannel = 'audio_channel';
  static const _prefSmartId3Tagging = 'smart_id3_tagging';
  static const _prefHapticFeedback = 'haptic_feedback';
  static const _prefCloudSync = 'cloud_sync';

  // State variables
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultQualityKbps = AppConstants.defaultQualityKbps;
  bool _adsRemoved = false;
  bool _normalizeVolume = false;
  bool _autoDeleteOriginal = false;

  // New settings
  AudioFormat _defaultFormat = AudioFormat.mp3;
  SampleRate _defaultSampleRate = SampleRate.sr44100;
  AudioChannel _defaultChannel = AudioChannel.stereo;
  bool _smartId3Tagging = true;
  bool _hapticFeedback = true;
  bool _cloudSyncEnabled = false;

  /// The active theme mode. Defaults to [ThemeMode.system].
  ThemeMode get themeMode => _themeMode;

  /// Convenience getter — `true` when the resolved theme is dark.
  ///
  /// For [ThemeMode.system] this falls back to `true` since we cannot
  /// query the platform from a non-widget class. The actual rendering
  /// defers to [MaterialApp.themeMode] which handles system correctly.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// The user's preferred audio quality in kbps.
  int get defaultQualityKbps => _defaultQualityKbps;

  /// Whether the user has purchased ad removal.
  bool get adsRemoved => _adsRemoved;

  /// Whether volume normalisation is enabled during conversion.
  bool get normalizeVolume => _normalizeVolume;

  /// Whether the original video should be deleted after conversion.
  bool get autoDeleteOriginal => _autoDeleteOriginal;

  // New getters
  /// The default audio format for conversions.
  AudioFormat get defaultFormat => _defaultFormat;

  /// The default sample rate for audio output.
  SampleRate get defaultSampleRate => _defaultSampleRate;

  /// The default audio channel configuration.
  AudioChannel get defaultChannel => _defaultChannel;

  /// Whether to automatically tag audio files with metadata.
  bool get smartId3Tagging => _smartId3Tagging;

  /// Whether haptic feedback is enabled.
  bool get hapticFeedback => _hapticFeedback;

  /// Whether cloud sync to Google Drive is enabled.
  bool get cloudSyncEnabled => _cloudSyncEnabled;

  /// Loads persisted settings from disk. Call once at app startup.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme
      final themeName = prefs.getString(_prefThemeMode);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      );

      // Quality
      _defaultQualityKbps =
          prefs.getInt(AppConstants.prefDefaultQuality) ??
          AppConstants.defaultQualityKbps;

      // Ads
      _adsRemoved = prefs.getBool(AppConstants.prefAdsRemoved) ?? false;

      // Audio settings
      _normalizeVolume = prefs.getBool(_prefNormalizeVolume) ?? false;
      _autoDeleteOriginal = prefs.getBool(_prefAutoDelete) ?? false;

      // Format settings
      final formatExt = prefs.getString(_prefAudioFormat) ?? 'mp3';
      _defaultFormat = AudioFormat.fromExtension(formatExt);

      final sampleRateHz = prefs.getInt(_prefSampleRate) ?? 44100;
      _defaultSampleRate = SampleRate.fromHz(sampleRateHz);

      final channelCount = prefs.getInt(_prefAudioChannel) ?? 2;
      _defaultChannel = AudioChannel.fromCount(channelCount);

      // Feature toggles
      _smartId3Tagging = prefs.getBool(_prefSmartId3Tagging) ?? true;
      _hapticFeedback = prefs.getBool(_prefHapticFeedback) ?? true;
      _cloudSyncEnabled = prefs.getBool(_prefCloudSync) ?? false;
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to load settings',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
    notifyListeners();
  }

  /// Sets the app theme mode and persists the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeMode, mode.name);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to persist theme mode',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Updates the default quality and persists the choice.
  Future<void> setDefaultQuality(int kbps) async {
    _defaultQualityKbps = kbps;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.prefDefaultQuality, kbps);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to save quality',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Toggles the normalize-volume flag and persists it.
  Future<void> toggleNormalizeVolume() async {
    _normalizeVolume = !_normalizeVolume;
    notifyListeners();
    await _saveBool(_prefNormalizeVolume, _normalizeVolume);
  }

  /// Toggles the auto-delete-original flag and persists it.
  Future<void> toggleAutoDeleteOriginal() async {
    _autoDeleteOriginal = !_autoDeleteOriginal;
    notifyListeners();
    await _saveBool(_prefAutoDelete, _autoDeleteOriginal);
  }

  /// Marks ads as removed (called after successful IAP).
  Future<void> markAdsRemoved() async {
    _adsRemoved = true;
    notifyListeners();
    await _saveBool(AppConstants.prefAdsRemoved, true);
  }

  // ─── New Setters ────────────────────────────────────────────────────

  /// Sets the default audio format.
  Future<void> setDefaultFormat(AudioFormat format) async {
    _defaultFormat = format;
    notifyListeners();
    await _saveString(_prefAudioFormat, format.extension);
  }

  /// Sets the default sample rate.
  Future<void> setDefaultSampleRate(SampleRate sampleRate) async {
    _defaultSampleRate = sampleRate;
    notifyListeners();
    await _saveInt(_prefSampleRate, sampleRate.hz);
  }

  /// Sets the default audio channel configuration.
  Future<void> setDefaultChannel(AudioChannel channel) async {
    _defaultChannel = channel;
    notifyListeners();
    await _saveInt(_prefAudioChannel, channel.count);
  }

  /// Toggles the smart ID3 tagging feature.
  Future<void> toggleSmartId3Tagging() async {
    _smartId3Tagging = !_smartId3Tagging;
    notifyListeners();
    await _saveBool(_prefSmartId3Tagging, _smartId3Tagging);
  }

  /// Toggles haptic feedback.
  Future<void> toggleHapticFeedback() async {
    _hapticFeedback = !_hapticFeedback;
    notifyListeners();
    await _saveBool(_prefHapticFeedback, _hapticFeedback);

    // Provide immediate feedback when enabling
    if (_hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Toggles cloud sync.
  Future<void> toggleCloudSync() async {
    _cloudSyncEnabled = !_cloudSyncEnabled;
    notifyListeners();
    await _saveBool(_prefCloudSync, _cloudSyncEnabled);
  }

  /// Performs haptic feedback if enabled.
  void performHaptic() {
    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  // ─── Private ────────────────────────────────────────────────────────

  /// Saves a boolean preference, logging errors instead of crashing.
  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to persist $key',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Saves a string preference, logging errors instead of crashing.
  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to persist $key',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }

  /// Saves an integer preference, logging errors instead of crashing.
  Future<void> _saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to persist $key',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
    }
  }
}
