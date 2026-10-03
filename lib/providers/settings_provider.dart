import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/audio_quality.dart';
import '../models/convert_options.dart';
import '../models/output_format.dart';
import '../utils/logger.dart';

/// User preferences: theme and the Studio's defaults.
class SettingsProvider extends ChangeNotifier {
  static const _tag = 'Settings';
  static const _prefNormalizeVolume = 'normalize_volume';
  static const _prefThemeMode = 'theme_mode';
  static const _prefFormat = 'default_format';
  static const _prefAlbumArt = 'album_art';
  static const _prefShareTipDismissed = 'share_tip_dismissed';

  ThemeMode _themeMode = ThemeMode.system;
  int _defaultQualityKbps = AppConstants.defaultQualityKbps;
  OutputFormat _defaultFormat = OutputFormat.mp3;
  bool _normalizeVolume = false;
  bool _albumArt = true;
  bool _shareTipDismissed = false;

  ThemeMode get themeMode => _themeMode;
  int get defaultQualityKbps => _defaultQualityKbps;
  OutputFormat get defaultFormat => _defaultFormat;
  bool get normalizeVolume => _normalizeVolume;
  bool get albumArt => _albumArt;
  bool get shareTipDismissed => _shareTipDismissed;

  /// Starting point for a fresh Studio session.
  ConvertOptions get defaultOptions => ConvertOptions(
    format: _defaultFormat,
    quality: AudioQuality.fromKbps(_defaultQualityKbps),
    normalize: _normalizeVolume,
    albumArt: _albumArt,
  );

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
      _defaultFormat = OutputFormat.fromName(prefs.getString(_prefFormat));
      _normalizeVolume = prefs.getBool(_prefNormalizeVolume) ?? false;
      _albumArt = prefs.getBool(_prefAlbumArt) ?? true;
      _shareTipDismissed = prefs.getBool(_prefShareTipDismissed) ?? false;
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

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _save((p) => p.setString(_prefThemeMode, mode.name));
  }

  Future<void> setDefaultQuality(int kbps) async {
    _defaultQualityKbps = kbps;
    notifyListeners();
    await _save((p) => p.setInt(AppConstants.prefDefaultQuality, kbps));
  }

  Future<void> setDefaultFormat(OutputFormat format) async {
    _defaultFormat = format;
    notifyListeners();
    await _save((p) => p.setString(_prefFormat, format.name));
  }

  Future<void> toggleNormalizeVolume() async {
    _normalizeVolume = !_normalizeVolume;
    notifyListeners();
    await _save((p) => p.setBool(_prefNormalizeVolume, _normalizeVolume));
  }

  Future<void> toggleAlbumArt() async {
    _albumArt = !_albumArt;
    notifyListeners();
    await _save((p) => p.setBool(_prefAlbumArt, _albumArt));
  }

  Future<void> dismissShareTip() async {
    _shareTipDismissed = true;
    notifyListeners();
    await _save((p) => p.setBool(_prefShareTipDismissed, true));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } on Exception catch (e, st) {
      Logger.error('Failed to persist', error: e, stackTrace: st, tag: _tag);
    }
  }
}
