import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mp3_extract/constants/app_constants.dart';
import 'package:mp3_extract/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsProvider', () {
    late SettingsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = SettingsProvider();
    });

    test('has correct defaults before loadSettings', () {
      expect(provider.themeMode, ThemeMode.system);
      expect(provider.defaultQualityKbps, AppConstants.defaultQualityKbps);
      expect(provider.adsRemoved, isFalse);
      expect(provider.normalizeVolume, isFalse);
      expect(provider.autoDeleteOriginal, isFalse);
    });

    test('loadSettings reads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'light',
        AppConstants.prefDefaultQuality: 320,
        AppConstants.prefAdsRemoved: true,
        'normalize_volume': true,
        'auto_delete_original': true,
      });

      final p = SettingsProvider();
      await p.loadSettings();

      expect(p.themeMode, ThemeMode.light);
      expect(p.defaultQualityKbps, 320);
      expect(p.adsRemoved, isTrue);
      expect(p.normalizeVolume, isTrue);
      expect(p.autoDeleteOriginal, isTrue);
    });

    test('loadSettings uses defaults when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});

      await provider.loadSettings();

      expect(provider.themeMode, ThemeMode.system);
      expect(provider.defaultQualityKbps, AppConstants.defaultQualityKbps);
      expect(provider.adsRemoved, isFalse);
      expect(provider.normalizeVolume, isFalse);
      expect(provider.autoDeleteOriginal, isFalse);
    });

    test('setThemeMode switches and persists', () async {
      await provider.loadSettings();
      expect(provider.themeMode, ThemeMode.system);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
    });

    test('setDefaultQuality persists kbps', () async {
      await provider.loadSettings();
      await provider.setDefaultQuality(320);

      expect(provider.defaultQualityKbps, 320);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(AppConstants.prefDefaultQuality), 320);
    });

    test('toggleNormalizeVolume switches and persists', () async {
      await provider.loadSettings();
      expect(provider.normalizeVolume, isFalse);

      await provider.toggleNormalizeVolume();
      expect(provider.normalizeVolume, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('normalize_volume'), isTrue);
    });

    test('toggleAutoDeleteOriginal switches and persists', () async {
      await provider.loadSettings();
      expect(provider.autoDeleteOriginal, isFalse);

      await provider.toggleAutoDeleteOriginal();
      expect(provider.autoDeleteOriginal, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auto_delete_original'), isTrue);
    });

    test('markAdsRemoved sets flag and persists', () async {
      await provider.loadSettings();
      expect(provider.adsRemoved, isFalse);

      await provider.markAdsRemoved();
      expect(provider.adsRemoved, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.prefAdsRemoved), isTrue);
    });

    test('notifies listeners on every mutation', () async {
      await provider.loadSettings();

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setThemeMode(ThemeMode.dark);
      expect(notifyCount, greaterThan(0));

      final before = notifyCount;
      await provider.setDefaultQuality(128);
      expect(notifyCount, greaterThan(before));
    });
  });
}
