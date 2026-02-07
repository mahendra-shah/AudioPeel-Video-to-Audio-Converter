import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/audio_channel.dart';
import '../models/audio_format.dart';
import '../models/audio_quality.dart';
import '../models/sample_rate.dart';
import '../providers/ad_provider.dart';
import '../providers/settings_provider.dart';
import '../services/cache_service.dart';
import '../services/iap_service.dart';
import '../services/storage_service.dart';
import '../utils/format_utils.dart';

/// Settings screen matching the reference design with grouped sections.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storageService = StorageService();
  final _cacheService = CacheService();
  String _outputPath = '';
  int _cacheSizeBytes = 0;
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
    _loadCacheSize();
  }

  Future<void> _loadStorageInfo() async {
    final path = await _storageService.outputDirectory();
    if (mounted) {
      setState(() => _outputPath = path);
    }
  }

  Future<void> _loadCacheSize() async {
    setState(() => _isLoadingCache = true);
    final size = await _cacheService.getCacheSize();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = size;
        _isLoadingCache = false;
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
          onPressed: () {
            settings.performHaptic();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingScreen,
          vertical: AppConstants.spacingSmall,
        ),
        children: [
          // ── EXTRACTION ENGINE ─────────────────────────────────────
          const _SectionHeader(title: AppStrings.extractionEngine),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.audio_file_rounded,
            iconColor: const Color(0xFF8B5CF6), // Purple
            title: AppStrings.defaultFormat,
            subtitle: settings.defaultFormat.displayName,
            onTap: () {
              settings.performHaptic();
              _showFormatPicker(settings);
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.graphic_eq_rounded,
            iconColor: const Color(0xFF3B82F6), // Blue
            title: AppStrings.bitrate,
            subtitle: AudioQuality.fromKbps(settings.defaultQualityKbps).label,
            subtitleExtra: '${settings.defaultQualityKbps} kbps',
            onTap: () {
              settings.performHaptic();
              _showBitratePicker(settings);
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.settings_input_antenna_rounded,
            iconColor: const Color(0xFF10B981), // Green
            title: AppStrings.sampleRate,
            subtitle: settings.defaultSampleRate.displayName,
            onTap: () {
              settings.performHaptic();
              _showSampleRatePicker(settings);
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.speaker_group_rounded,
            iconColor: const Color(0xFF8B5CF6), // Purple
            title: AppStrings.channel,
            subtitle: settings.defaultChannel.displayName,
            onTap: () {
              settings.performHaptic();
              _showChannelPicker(settings);
            },
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── AUTOMATION ────────────────────────────────────────────
          const _SectionHeader(title: AppStrings.automation),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.sell_rounded,
            iconColor: const Color(0xFF10B981), // Green
            title: AppStrings.smartId3Tagging,
            subtitle: AppStrings.smartId3Description,
            value: settings.smartId3Tagging,
            onChanged: (_) {
              settings.performHaptic();
              settings.toggleSmartId3Tagging();
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.auto_delete_rounded,
            iconColor: AppColors.error,
            title: AppStrings.autoDeleteSource,
            subtitle: AppStrings.autoDeleteSourceDescription,
            value: settings.autoDeleteOriginal,
            onChanged: (_) {
              settings.performHaptic();
              settings.toggleAutoDeleteOriginal();
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.volume_up_rounded,
            iconColor: const Color(0xFFF59E0B), // Orange
            title: AppStrings.normalizeVolume,
            subtitle: AppStrings.normalizeVolumeDescription,
            value: settings.normalizeVolume,
            onChanged: (_) {
              settings.performHaptic();
              settings.toggleNormalizeVolume();
            },
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── STORAGE ───────────────────────────────────────────────
          const _SectionHeader(title: AppStrings.storage),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.folder_rounded,
            iconColor: const Color(0xFF3B82F6), // Blue
            title: AppStrings.outputPath,
            subtitle: _outputPath.isEmpty ? 'Loading...' : _outputPath,
            onTap: () {
              settings.performHaptic();
              _onChangeOutputPath();
            },
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── EXPERIENCE ────────────────────────────────────────────
          const _SectionHeader(title: AppStrings.experience),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.palette_rounded,
            iconColor: const Color(0xFFFBBF24), // Yellow
            title: AppStrings.theme,
            subtitle: _getThemeName(settings.themeMode),
            onTap: () {
              settings.performHaptic();
              _showThemePicker(settings);
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _ToggleTile(
            icon: Icons.vibration_rounded,
            iconColor: const Color(0xFFEC4899), // Pink
            title: AppStrings.hapticFeedback,
            subtitle: AppStrings.hapticDescription,
            value: settings.hapticFeedback,
            onChanged: (_) => settings.toggleHapticFeedback(),
          ),

          const SizedBox(height: AppConstants.spacingSection),

          // ── SUPPORT ───────────────────────────────────────────────
          const _SectionHeader(title: AppStrings.support),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.cleaning_services_rounded,
            iconColor: const Color(0xFF64748B), // Gray
            title: AppStrings.clearCache,
            subtitle: _isLoadingCache
                ? 'Calculating...'
                : FormatUtils.fileSize(_cacheSizeBytes),
            onTap: () {
              settings.performHaptic();
              _onClearCache();
            },
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          _NavigationTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: AppStrings.aboutVibe,
            subtitle: AppStrings.versionValue,
            onTap: () {
              settings.performHaptic();
              _showAbout();
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

  // ─── Pickers ────────────────────────────────────────────────────────

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppStrings.systemTheme;
      case ThemeMode.light:
        return AppStrings.lightTheme;
      case ThemeMode.dark:
        return AppStrings.oledDark;
    }
  }

  void _showFormatPicker(SettingsProvider settings) {
    showModalBottomSheet<AudioFormat>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingScreen),
                    child: Text(
                      AppStrings.selectFormat,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: AudioFormat.values.map((format) {
                        final isSelected = format == settings.defaultFormat;
                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? AppColors.primary : null,
                          ),
                          title: Text(format.displayName),
                          subtitle: Text('.${format.extension}'),
                          onTap: () {
                            Navigator.of(ctx).pop(format);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSmall),
                ],
              );
            },
          ),
        );
      },
    ).then((format) {
      if (format != null) {
        settings.setDefaultFormat(format);
      }
    });
  }

  void _showBitratePicker(SettingsProvider settings) {
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
                  AppStrings.selectBitrate,
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

  void _showSampleRatePicker(SettingsProvider settings) {
    showModalBottomSheet<SampleRate>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingScreen),
                child: Text(
                  AppStrings.selectSampleRate,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...SampleRate.values.map((rate) {
                final isSelected = rate == settings.defaultSampleRate;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  title: Text(rate.displayName),
                  onTap: () => Navigator.of(ctx).pop(rate),
                );
              }),
              const SizedBox(height: AppConstants.spacingSmall),
            ],
          ),
        );
      },
    ).then((rate) {
      if (rate != null) {
        settings.setDefaultSampleRate(rate);
      }
    });
  }

  void _showChannelPicker(SettingsProvider settings) {
    showModalBottomSheet<AudioChannel>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingScreen),
                child: Text(
                  AppStrings.selectChannel,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...AudioChannel.values.map((channel) {
                final isSelected = channel == settings.defaultChannel;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : null,
                  ),
                  title: Text(channel.displayName),
                  onTap: () => Navigator.of(ctx).pop(channel),
                );
              }),
              const SizedBox(height: AppConstants.spacingSmall),
            ],
          ),
        );
      },
    ).then((channel) {
      if (channel != null) {
        settings.setDefaultChannel(channel);
      }
    });
  }

  void _showThemePicker(SettingsProvider settings) {
    showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingScreen),
                child: Text(
                  'Select Theme',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  settings.themeMode == ThemeMode.system
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: settings.themeMode == ThemeMode.system
                      ? AppColors.primary
                      : null,
                ),
                title: const Text('System'),
                onTap: () => Navigator.of(ctx).pop(ThemeMode.system),
              ),
              ListTile(
                leading: Icon(
                  settings.themeMode == ThemeMode.light
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: settings.themeMode == ThemeMode.light
                      ? AppColors.primary
                      : null,
                ),
                title: const Text('Light'),
                onTap: () => Navigator.of(ctx).pop(ThemeMode.light),
              ),
              ListTile(
                leading: Icon(
                  settings.themeMode == ThemeMode.dark
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: settings.themeMode == ThemeMode.dark
                      ? AppColors.primary
                      : null,
                ),
                title: const Text('OLED Dark'),
                onTap: () => Navigator.of(ctx).pop(ThemeMode.dark),
              ),
              const SizedBox(height: AppConstants.spacingSmall),
            ],
          ),
        );
      },
    ).then((mode) {
      if (mode != null) {
        settings.setThemeMode(mode);
      }
    });
  }

  // ─── Actions ────────────────────────────────────────────────────────

  Future<void> _onChangeOutputPath() async {
    final selectedDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Output Folder',
    );

    if (selectedDir == null || !mounted) return;

    _storageService.setOutputDirectory(selectedDir);
    setState(() => _outputPath = selectedDir);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Output path set to: $selectedDir')),
      );
    }
  }

  Future<void> _onClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _cacheService.clearCache();
      await _loadCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.cacheCleared)));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
      }
    }
  }

  Future<void> _onRestorePurchases() async {
    // Show loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final iap = context.read<IapService>();
      await iap.restorePurchases();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      final success = iap.isPurchased;
      if (success) {
        context.read<SettingsProvider>().markAdsRemoved();
        context.read<AdProvider>().markAdsRemoved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No purchases found')));
      }
    } on Exception catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore purchases: $e')),
      );
    }
  }

  void _showCloudSyncInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud Sync'),
        content: const Text(
          'Cloud sync feature is coming soon! This will allow automatic '
          'backup of your converted files to Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appNameAbout,
      applicationVersion: AppStrings.versionValue,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'android_icon/ic_launcher-web.png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to old icon if new one is not found
            return Image.asset(
              'assets/icon/app_icon.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            );
          },
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
  }

  Future<void> _onRemoveAds(SettingsProvider settings) async {
    final iap = context.read<IapService>();
    await iap.purchaseRemoveAds();

    iap.addListener(() {
      if (!mounted) return;
      if (iap.isPurchased) {
        settings.markAdsRemoved();
        context.read<AdProvider>().markAdsRemoved();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.adsRemoved)));
      } else if (iap.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(iap.error!)));
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Reusable private widgets
// ═══════════════════════════════════════════════════════════════════════

/// Prominent amber "Remove Ads" CTA at the top of the screen.
class _RemoveAdsBanner extends StatelessWidget {
  const _RemoveAdsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        child: SizedBox(
          height: AppConstants.buttonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.black87),
              const SizedBox(width: AppConstants.spacingSmall),
              Text(
                AppStrings.removeAds,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase section heading (e.g. "EXTRACTION ENGINE").
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

/// Card-shaped row with an icon, title, optional subtitle, and a chevron.
class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleExtra,
    required this.onTap,
  });

  final IconData icon;
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
          _CircleIcon(icon: icon, color: iconColor),
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
  const _CircleIcon({required this.icon, required this.color});

  final IconData icon;
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
      child: Icon(icon, color: color, size: 20),
    );
  }
}
