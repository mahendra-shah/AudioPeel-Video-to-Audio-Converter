import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_strings.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/audio_quality.dart';
import '../models/output_format.dart';
import '../providers/settings_provider.dart';
import '../services/consent_service.dart';
import '../services/media_bridge.dart';
import '../services/review_service.dart';
import '../services/storage_service.dart';
import '../widgets/pill_selector.dart';
import '../widgets/section_card.dart';

// ---------------------------------------------------------------------------
// Settings Screen
// ---------------------------------------------------------------------------

/// User-facing settings: conversion defaults, appearance, storage and about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppStrings.settingsTitle,
          style: TextStyle(
            fontFamily: 'Jakarta',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        iconTheme: IconThemeData(color: p.inkMuted),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.md,
        ),
        children: [
          _DefaultsSection(),
          const SizedBox(height: Space.xl),
          _AppearanceSection(),
          const SizedBox(height: Space.xl),
          _StorageSection(),
          const SizedBox(height: Space.xl),
          _AboutSection(version: _version),
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Defaults Section
// ---------------------------------------------------------------------------

class _DefaultsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.peel;

    return SectionCard(
      title: AppStrings.settingsSectionDefaults,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format
          _SettingsLabel(label: AppStrings.settingsFormat),
          const SizedBox(height: Space.xs),
          SizedBox(
            width: double.infinity,
            child: PillSelector<OutputFormat>(
              items: OutputFormat.values,
              selected: settings.defaultFormat,
              label: (f) => f.label,
              onChanged: (f) => settings.setDefaultFormat(f),
            ),
          ),
          const SizedBox(height: Space.md),

          // Quality (only relevant for lossy formats)
          AnimatedSize(
            duration: Motion.short,
            curve: Motion.standard,
            child: settings.defaultFormat.lossless
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsLabel(label: AppStrings.settingsQuality),
                      const SizedBox(height: Space.xs),
                      SizedBox(
                        width: double.infinity,
                        child: PillSelector<AudioQuality>(
                          items: AudioQuality.values,
                          selected: AudioQuality.fromKbps(
                            settings.defaultQualityKbps,
                          ),
                          label: (q) => '${q.kbps}k',
                          onChanged: (q) => settings.setDefaultQuality(q.kbps),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                    ],
                  ),
          ),

          // Normalize volume
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppStrings.settingsNormalizeVolume,
              style: _rowTitleStyle(context),
            ),
            subtitle: Text(
              AppStrings.settingsNormalizeVolumeSubtitle,
              style: _rowSubtitleStyle(context),
            ),
            value: settings.normalizeVolume,
            activeColor: p.peel,
            onChanged: (_) {
              Haptics.select();
              settings.toggleNormalizeVolume();
            },
          ),

          // Album art
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              AppStrings.settingsAlbumArt,
              style: _rowTitleStyle(context),
            ),
            subtitle: Text(
              AppStrings.settingsAlbumArtSubtitle,
              style: _rowSubtitleStyle(context),
            ),
            value: settings.albumArt,
            activeColor: p.peel,
            onChanged: (_) {
              Haptics.select();
              settings.toggleAlbumArt();
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance Section
// ---------------------------------------------------------------------------

class _AppearanceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return SectionCard(
      title: AppStrings.settingsSectionAppearance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsLabel(label: AppStrings.settingsTheme),
          const SizedBox(height: Space.xs),
          SizedBox(
            width: double.infinity,
            child: PillSelector<ThemeMode>(
              items: ThemeMode.values,
              selected: settings.themeMode,
              label: (m) {
                switch (m) {
                  case ThemeMode.system:
                    return AppStrings.settingsThemeSystem;
                  case ThemeMode.light:
                    return AppStrings.settingsThemeLight;
                  case ThemeMode.dark:
                    return AppStrings.settingsThemeDark;
                }
              },
              onChanged: (m) {
                Haptics.select();
                settings.setThemeMode(m);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Storage Section
// ---------------------------------------------------------------------------

class _StorageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    final storage = const StorageService();

    return SectionCard(
      title: AppStrings.settingsSectionStorage,
      child: Column(
        children: [
          // Saved to
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: p.inkMuted, size: 22),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.settingsSavedTo,
                        style: _rowTitleStyle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        storage.getOutputDirectoryDisplay(),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Open folder
          _TapRow(
            icon: Icons.open_in_new_outlined,
            label: AppStrings.settingsOpenFolder,
            onTap: () => MediaBridge.openFolder(),
          ),

          // Clear cache
          _TapRow(
            icon: Icons.cleaning_services_outlined,
            label: AppStrings.settingsClearCache,
            onTap: () => _confirmClearCache(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.settingsClearCacheConfirmTitle),
        content: const Text(AppStrings.settingsClearCacheConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.confirm,
              style: TextStyle(color: context.peel.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await const StorageService().clearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsClearCacheSuccess)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// About Section
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppStrings.settingsSectionAbout,
      child: Column(
        children: [
          _TapRow(
            icon: Icons.star_outline,
            label: AppStrings.settingsRate,
            onTap: () => ReviewService.openStore(),
          ),
          _TapRow(
            icon: Icons.share_outlined,
            label: AppStrings.settingsShareApp,
            onTap: () => _launchUrl(AppStrings.playStoreUrl),
          ),
          _TapRow(
            icon: Icons.privacy_tip_outlined,
            label: AppStrings.settingsPrivacyPolicy,
            onTap: () => _launchUrl(AppStrings.privacyPolicyUrl),
          ),
          if (ConsentService.privacyOptionsRequired)
            _TapRow(
              icon: Icons.tune_outlined,
              label: AppStrings.settingsPrivacyOptions,
              onTap: () => ConsentService.showPrivacyOptions(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.peel.inkMuted,
                  size: 22,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    AppStrings.settingsVersion,
                    style: _rowTitleStyle(context),
                  ),
                ),
                Text(
                  version,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 12,
                    color: context.peel.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// Shared row helpers
// ---------------------------------------------------------------------------

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    final effectiveColor = color ?? p.ink;

    return InkWell(
      onTap: () {
        Haptics.tap();
        onTap();
      },
      borderRadius: BorderRadius.circular(Radii.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Jakarta',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: effectiveColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: p.inkFaint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.peel.inkMuted,
      ),
    );
  }
}

TextStyle _rowTitleStyle(BuildContext context) => TextStyle(
      fontFamily: 'Jakarta',
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: context.peel.ink,
    );

TextStyle _rowSubtitleStyle(BuildContext context) => TextStyle(
      fontFamily: 'Jakarta',
      fontSize: 12,
      color: context.peel.inkMuted,
    );
