import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Manages user preferences such as theme mode and default quality.
///
/// Persists state via [SharedPreferences] so choices survive restarts.
class SettingsProvider extends ChangeNotifier {
  static const _tag = 'Settings';
  static const _prefNormalizeVolume = 'normalize_volume';
  static const _prefAutoDelete = 'auto_delete_original';
  static const _prefThemeMode = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  int _defaultQualityKbps = AppConstants.defaultQualityKbps;
  bool _normalizeVolume = false;
  bool _autoDeleteOriginal = false;

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

  /// Whether volume normalisation is enabled during conversion.
  bool get normalizeVolume => _normalizeVolume;

  /// Whether the original video should be deleted after conversion.
  bool get autoDeleteOriginal => _autoDeleteOriginal;

  /// Loads persisted settings from disk. Call once at app startup.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_prefThemeMode);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      );
      _defaultQualityKbps =
          prefs.getInt(AppConstants.prefDefaultQuality) ??
          AppConstants.defaultQualityKbps;
      _normalizeVolume = prefs.getBool(_prefNormalizeVolume) ?? false;
      _autoDeleteOriginal = prefs.getBool(_prefAutoDelete) ?? false;
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
}
