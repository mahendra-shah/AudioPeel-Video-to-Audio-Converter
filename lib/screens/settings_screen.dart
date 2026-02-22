import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_colors.dart';
import '../widgets/common/audio_icon.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/audio_quality.dart';
import '../providers/ad_provider.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';

/// Settings screen with grouped sections matching the design:
/// Remove Ads CTA, Audio Settings, Appearance & Behavior, Storage, About.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageService = StorageService();
  String _outputPath = '';

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final path = await _storageService.outputDirectory();
    if (mounted) {
      setState(() {
        _outputPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingScreen,
          vertical: AppConstants.spacingSmall,
        ),
        children: [
          // ── Appearance & Behavior ─────────────────────────────────
          const _SectionHeader(title: AppStrings.appearanceAndBehavior),
          const SizedBox(height: AppConstants.spacingSmall),
          _ThemeModeTile(
            currentMode: settings.themeMode,
            onChanged: settings.setThemeMode,
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── Audio Settings ────────────────────────────────────────
          const _SectionHeader(title: AppStrings.audioSettings),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            iconWidget: const AudioIcon(size: 20, color: AppColors.primary),
            iconColor: AppColors.primary,
            title: AppStrings.audioQualityLabel,
            subtitle: AudioQuality.fromKbps(settings.defaultQualityKbps).label,
            subtitleExtra: '(${settings.defaultQualityKbps}kbps)',
            onTap: () => _showQualityPicker(settings),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.equalizer_rounded,
            iconColor: AppColors.primary,
            title: AppStrings.normalizeVolume,
            value: settings.normalizeVolume,
            onChanged: (_) => settings.toggleNormalizeVolume(),
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── Storage & Files ───────────────────────────────────────
          const _SectionHeader(title: AppStrings.storage),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.folder_rounded,
            iconColor: AppColors.success,
            title: AppStrings.outputPath,
            subtitle: _outputPath,
            onTap: _onChangeOutputPath,
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.auto_delete_rounded,
            iconColor: AppColors.error,
            title: AppStrings.autoDeleteOriginal,
            subtitle: AppStrings.autoDeleteDescription,
            value: settings.autoDeleteOriginal,
            onChanged: (_) => settings.toggleAutoDeleteOriginal(),
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── About ─────────────────────────────────────────────────
          const _SectionHeader(title: AppStrings.about),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.radio_rounded,
            iconColor: AppColors.textSecondaryDark,
            title: AppStrings.appNameAbout,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppStrings.appNameAbout,
                applicationVersion: AppStrings.versionValue,
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                applicationLegalese: AppStrings.copyright,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A fast, offline video-to-audio converter. '
                    'Extract audio from any video format with ease.',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          const _InfoTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: AppStrings.version,
            trailing: AppStrings.versionValue,
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.policy_rounded,
            iconColor: AppColors.primary,
            title: AppStrings.privacyPolicy,
            subtitle: 'Learn how we protect your data',
            onTap: () async {
              final uri = Uri.parse('https://mahendra-shah.github.io/AudioPeel-Video-to-Audio-Converter/PRIVACY_POLICY');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open privacy policy'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),

          // ── Footer ────────────────────────────────────────────────
          const SizedBox(height: AppConstants.spacingSection + 8),
          Center(
            child: Text(
              AppStrings.copyright,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingSection),
        ],
      ),
    );
  }

  // ─── Quality Picker ─────────────────────────────────────────────────

  void _showQualityPicker(SettingsProvider settings) {
    showModalBottomSheet<AudioQuality>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingScreen),
                child: Text(
                  AppStrings.selectQuality,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...AudioQuality.values.map((q) {
                final isSelected = q.kbps == settings.defaultQualityKbps;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  title: Text('${q.label} (${q.displayName})'),
                  onTap: () => Navigator.of(ctx).pop(q),
                );
              }),
              const SizedBox(height: AppConstants.spacingSmall),
            ],
          ),
        );
      },
    ).then((quality) {
      if (quality != null) {
        settings.setDefaultQuality(quality.kbps);
      }
    });
  }

  // ─── Change Output Path ─────────────────────────────────────────────

  Future<void> _onChangeOutputPath() async {
    final selectedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Folder',
    );

    if (selectedDir == null || !mounted) return;

    _storageService.setOutputDirectory(selectedDir);
    setState(() => _outputPath = selectedDir);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Output path set to: $selectedDir')));
  }
}

// ─── Section Header ───────────────────────────────────────────────────

/// Uppercase section heading (e.g. "AUDIO SETTINGS").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─── Toggle Tile ──────────────────────────────────────────────────────

/// Card-shaped row with an icon, title, optional subtitle, and a switch.
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _TileCard(
      child: Row(
        children: [
          _CircleIcon(icon: icon, color: iconColor),
          const SizedBox(width: AppConstants.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Navigation Tile ──────────────────────────────────────────────────

/// Card-shaped row with an icon, title, optional subtitle, and a chevron.
class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    this.icon,
    this.iconWidget,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleExtra,
    required this.onTap,
  }) : assert(icon != null || iconWidget != null,
            'Either icon or iconWidget must be provided');

  final IconData? icon;
  final Widget? iconWidget;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? subtitleExtra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TileCard(
      onTap: onTap,
      child: Row(
        children: [
          _CircleIcon(icon: icon, iconWidget: iconWidget, color: iconColor),
          const SizedBox(width: AppConstants.spacingSmall + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleExtra != null
                        ? '$subtitle $subtitleExtra'
                        : subtitle!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
    );
  }
}

// ─── Theme Mode Tile ──────────────────────────────────────────────────

/// A card tile letting the user choose between System, Light, and Dark
/// theme modes via a segmented control.
class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.currentMode, required this.onChanged});

  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CircleIcon(
                icon: Icons.palette_rounded,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: AppConstants.spacingSmall + 4),
              Text(
                'Theme',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_brightness_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded, size: 18),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (selected) => onChanged(selected.first),
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Tile ────────────────────────────────────────────────────────

/// Card-shaped row with an icon, title, and a trailing text value.
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _TileCard(
      child: Row(
        children: [
          _CircleIcon(icon: icon, color: iconColor),
          const SizedBox(width: AppConstants.spacingSmall + 4),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(trailing, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────

/// Card background shared by all setting tiles.
class _TileCard extends StatelessWidget {
  const _TileCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingScreen,
            vertical: 14,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small coloured circle containing an icon, used as the leading
/// element in every settings tile.
class _CircleIcon extends StatelessWidget {
  const _CircleIcon({this.icon, this.iconWidget, required this.color})
      : assert(icon != null || iconWidget != null,
            'Either icon or iconWidget must be provided');

  final IconData? icon;
  final Widget? iconWidget;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: iconWidget ?? Icon(icon, color: color, size: 20),
    );
  }
}
