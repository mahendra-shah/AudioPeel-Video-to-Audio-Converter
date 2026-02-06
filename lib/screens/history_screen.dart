import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/audio_file.dart';
import '../providers/history_provider.dart';
import '../services/ringtone_service.dart';
import '../services/storage_service.dart';
import '../utils/debouncer.dart';
import '../utils/format_utils.dart';
import '../widgets/common/banner_ad_widget.dart';
import '../widgets/common/empty_state.dart';

/// Full conversion history screen with search, filter chips, and a
/// date-grouped list of converted files.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(duration: AppConstants.searchDebounceDuration);

  @override
  void initState() {
    super.initState();
    // Load conversions after the first frame so Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadConversions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(AppStrings.conversionHistory),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _onMenuAction(value),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text(AppStrings.clearAllHistory),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingScreen,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppConstants.spacingSmall),
                _SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: AppConstants.spacingSmall + 4),
                const _FilterChips(),
                const SizedBox(height: AppConstants.spacingSmall),
              ],
            ),
          ),
          const Expanded(child: _HistoryList()),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (mounted) {
        context.read<HistoryProvider>().searchByName(query);
      }
    });
  }

  void _onMenuAction(String action) {
    if (action == 'clear') {
      _showClearConfirmation();
    }
  }

  void _showClearConfirmation() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.clearAllHistory),
        content: const Text(AppStrings.clearHistoryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<HistoryProvider>().clearAll();
      }
    });
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────

/// Rounded text field with a search icon prefix.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: AppStrings.searchConvertedFiles,
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────────────

/// Horizontal scrollable row of filter chips: All, Today, Last 7 Days,
/// High Quality.
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  static const _filters = [
    (HistoryFilter.all, AppStrings.allConversions),
    (HistoryFilter.today, AppStrings.todayFilter),
    (HistoryFilter.last7Days, AppStrings.last7Days),
    (HistoryFilter.highQuality, AppStrings.highQualityFilter),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilter = context.select<HistoryProvider, HistoryFilter>(
      (p) => p.filter,
    );

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppConstants.spacingSmall),
        itemBuilder: (_, index) {
          final (filter, label) = _filters[index];
          final isSelected = filter == activeFilter;

          return GestureDetector(
            onTap: () {
              context.read<HistoryProvider>().applyFilter(filter);
            },
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: theme.colorScheme.outline),
              ),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── History List ─────────────────────────────────────────────────────

/// Date-grouped list of conversion items, or an empty state.
class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HistoryProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.isEmpty) {
      return const EmptyState(
        icon: Icons.music_off_rounded,
        title: AppStrings.noHistoryYet,
        subtitle: AppStrings.noHistoryDescription,
      );
    }

    final grouped = _groupByDate(provider.conversions);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingScreen,
      ),
      itemCount: grouped.length,
      itemBuilder: (_, index) {
        final group = grouped[index];
        return _DateGroup(header: group.header, items: group.items);
      },
    );
  }

  /// Groups a flat list of [AudioFile] into date sections.
  List<_GroupedSection> _groupByDate(List<AudioFile> files) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final Map<String, List<AudioFile>> buckets = {};

    for (final file in files) {
      final created = file.createdAt;
      final String key;
      if (created.isAfter(todayStart) || created.isAtSameMomentAs(todayStart)) {
        key = AppStrings.today;
      } else if (created.isAfter(yesterdayStart) ||
          created.isAtSameMomentAs(yesterdayStart)) {
        key = AppStrings.yesterday;
      } else if (created.isAfter(weekStart)) {
        key = AppStrings.last7DaysHeader;
      } else {
        key = AppStrings.older;
      }
      (buckets[key] ??= []).add(file);
    }

    // Preserve a stable order.
    const order = [
      AppStrings.today,
      AppStrings.yesterday,
      AppStrings.last7DaysHeader,
      AppStrings.older,
    ];

    return [
      for (final header in order)
        if (buckets.containsKey(header))
          _GroupedSection(header: header, items: buckets[header]!),
    ];
  }
}

/// A date header + its items.
class _GroupedSection {
  const _GroupedSection({required this.header, required this.items});
  final String header;
  final List<AudioFile> items;
}

// ─── Date Group ───────────────────────────────────────────────────────

/// Renders a section header followed by its list of [_HistoryTile]s.
class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.header, required this.items});

  final String header;
  final List<AudioFile> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.spacingElement),
        Text(
          header,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        ...items.map(
          (file) => Dismissible(
            key: ValueKey(file.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
            confirmDismiss: (_) => _confirmSwipeDelete(context, file),
            onDismissed: (_) async {
              await StorageService().deleteFile(file.outputAudioPath);
              if (context.mounted && file.id != null) {
                context.read<HistoryProvider>().deleteConversion(file.id!);
              }
            },
            child: _HistoryTile(audioFile: file),
          ),
        ),
      ],
    );
  }

  static Future<bool> _confirmSwipeDelete(
    BuildContext context,
    AudioFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteConversion),
        content: Text('Delete "${file.outputAudioName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

// ─── History Tile ─────────────────────────────────────────────────────

/// A single row in the history list: icon, filename, meta, overflow menu.
class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.audioFile});

  final AudioFile audioFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationText = FormatUtils.duration(audioFile.duration);
    final sizeText = FormatUtils.fileSize(audioFile.fileSize);

    return InkWell(
      onTap: () =>
          OpenFilex.open(audioFile.outputAudioPath, type: 'audio/mpeg'),
      borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.spacingSmall,
        ),
        child: Row(
          children: [
            // Blue circle with music note.
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSmall + 4),

            // Filename + meta.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audioFile.outputAudioName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$durationText  •  $sizeText',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Overflow menu.
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: theme.textTheme.bodySmall?.color,
              ),
              onSelected: (action) => _onItemAction(context, action, audioFile),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'share',
                  child: Text(AppStrings.shareConversion),
                ),
                PopupMenuItem(
                  value: 'ringtone',
                  child: Text('Set as Ringtone'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(AppStrings.deleteConversion),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onItemAction(BuildContext context, String action, AudioFile file) {
    switch (action) {
      case 'share':
        SharePlus.instance.share(
          ShareParams(files: [XFile(file.outputAudioPath)]),
        );
      case 'ringtone':
        _setAsRingtone(context, file);
      case 'delete':
        _confirmDelete(context, file);
    }
  }

  Future<void> _setAsRingtone(BuildContext context, AudioFile file) async {
    // Check write settings permission first.
    final hasPermission = await RingtoneService.hasWriteSettingsPermission();
    if (!hasPermission) {
      if (!context.mounted) return;
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'To set a ringtone, the app needs the "Modify System Settings" '
            'permission. Would you like to open settings to grant it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.no),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (shouldOpen == true) {
        await RingtoneService.requestWriteSettings();
      }
      return;
    }

    final success = await RingtoneService.setAsRingtone(file.outputAudioPath);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '"${file.outputAudioName}" set as ringtone'
              : 'Failed to set ringtone',
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AudioFile file) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteConversion),
        content: Text('Delete "${file.outputAudioName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await StorageService().deleteFile(file.outputAudioPath);
        if (context.mounted && file.id != null) {
          context.read<HistoryProvider>().deleteConversion(file.id!);
        }
      }
    });
  }
}
