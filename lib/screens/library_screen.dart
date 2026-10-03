import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/audio_file.dart';
import '../models/output_format.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../services/media_bridge.dart';
import '../utils/debouncer.dart';
import '../utils/format_utils.dart';

// ---------------------------------------------------------------------------
// Library Screen
// ---------------------------------------------------------------------------

/// Conversion history screen with search, filter chips, grouped list, swipe-
/// to-delete with undo, and per-row action bottom sheets.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  final _debounce = Debouncer(
    duration: AppConstants.searchDebounceDuration,
  );
  bool _searchExpanded = false;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final history = context.read<HistoryProvider>();
      history.pruneMissing().then((_) => history.refresh());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce.run(() {
      context.read<HistoryProvider>().searchByName(q);
    });
  }

  void _toggleSearch() {
    setState(() => _searchExpanded = !_searchExpanded);
    if (_searchExpanded) {
      _searchFocus.requestFocus();
    } else {
      _searchCtrl.clear();
      _searchFocus.unfocus();
      context.read<HistoryProvider>().searchByName('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _SearchBar(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              expanded: _searchExpanded,
              onToggle: _toggleSearch,
              onChanged: _onSearchChanged,
            ),
            const _FilterRow(),
            const Expanded(child: _ConversionList()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onToggle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.short,
              child: expanded
                  ? _SearchField(
                      key: const ValueKey('search_field'),
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                    )
                  : Align(
                      key: const ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.libraryTitle,
                        style: TextStyle(
                          fontFamily: 'Jakarta',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: Space.xs),
          AnimatedSwitcher(
            duration: Motion.short,
            child: IconButton(
              key: ValueKey(expanded),
              icon: Icon(
                expanded ? Icons.close : Icons.search,
                color: p.inkMuted,
              ),
              onPressed: onToggle,
              tooltip: expanded ? 'Close search' : 'Search',
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'Jakarta',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: p.ink,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.librarySearchHint,
        hintStyle: TextStyle(color: p.inkFaint),
        filled: true,
        fillColor: p.surface,
        prefixIcon: Icon(Icons.search, color: p.inkFaint, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.xs,
        ),
        isDense: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Chips Row
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    final history = context.watch<HistoryProvider>();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        children: HistoryFilter.values.map((filter) {
          final selected = history.filter == filter &&
              history.searchQuery.isEmpty;
          return Padding(
            padding: const EdgeInsets.only(right: Space.xs),
            child: AnimatedContainer(
              duration: Motion.short,
              curve: Motion.standard,
              child: GestureDetector(
                onTap: () {
                  Haptics.select();
                  context.read<HistoryProvider>().applyFilter(filter);
                },
                child: Chip(
                  label: Text(filter.label),
                  labelStyle: TextStyle(
                    fontFamily: 'Jakarta',
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? p.onPeel : p.inkMuted,
                  ),
                  backgroundColor: selected ? p.peel : p.surface,
                  side: BorderSide(
                    color: selected ? p.peel : p.line,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversion List
// ---------------------------------------------------------------------------

class _ConversionList extends StatelessWidget {
  const _ConversionList();

  /// Group headers based on the createdAt date.
  List<_ListItem> _buildItems(List<AudioFile> files) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    String? _lastGroup;
    final items = <_ListItem>[];

    for (final file in files) {
      final d = DateTime(
        file.createdAt.year,
        file.createdAt.month,
        file.createdAt.day,
      );
      final String group;
      if (d == today) {
        group = AppStrings.libraryGroupToday;
      } else if (d == yesterday) {
        group = AppStrings.libraryGroupYesterday;
      } else if (d.isAfter(weekAgo)) {
        group = AppStrings.libraryGroupThisWeek;
      } else {
        group = AppStrings.libraryGroupOlder;
      }

      if (group != _lastGroup) {
        items.add(_ListItem.header(group));
        _lastGroup = group;
      }
      items.add(_ListItem.file(file));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    if (history.isLoading && !history.loadedOnce) {
      return Center(
        child: CircularProgressIndicator(
          color: context.peel.peel,
        ),
      );
    }

    if (history.isEmpty) {
      return const _EmptyState();
    }

    final items = _buildItems(history.conversions);

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: Space.gutter,
        right: Space.gutter,
        top: Space.sm,
        bottom: 120, // leave space for mini-player
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return _GroupHeader(label: item.label!);
        }
        return _AnimatedFileRow(
          file: item.file!,
          index: index,
        );
      },
    );
  }
}

class _ListItem {
  const _ListItem.header(String label)
      : label = label,
        file = null,
        isHeader = true;

  const _ListItem.file(AudioFile file)
      : file = file,
        label = null,
        isHeader = false;

  final bool isHeader;
  final String? label;
  final AudioFile? file;
}

// ---------------------------------------------------------------------------
// Group Header
// ---------------------------------------------------------------------------

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    return Padding(
      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xs),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Jakarta',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: p.inkFaint,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated File Row wrapper (stagger + swipe)
// ---------------------------------------------------------------------------

class _AnimatedFileRow extends StatefulWidget {
  const _AnimatedFileRow({required this.file, required this.index});
  final AudioFile file;
  final int index;

  @override
  State<_AnimatedFileRow> createState() => _AnimatedFileRowState();
}

class _AnimatedFileRowState extends State<_AnimatedFileRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Motion.medium);
    _fade = CurvedAnimation(parent: _ctrl, curve: Motion.emphasizedDecel);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Motion.emphasizedDecel));

    final delay = Motion.staggerFor(widget.index);
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDismissed(AudioFile file) {
    final history = context.read<HistoryProvider>();
    history.stageDelete(file);

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text(AppStrings.libraryDeletedSnackbar),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppStrings.libraryUndoLabel,
              onPressed: () => history.undoDelete(file),
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        history.commitDelete(file);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Dismissible(
          key: ValueKey(widget.file.id ?? widget.file.outputAudioPath),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: Space.lg),
            margin: const EdgeInsets.only(bottom: Space.xs),
            decoration: BoxDecoration(
              color: p.danger,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (_) async => true,
          onDismissed: (_) => _onDismissed(widget.file),
          child: _FileRow(file: widget.file),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// File Row
// ---------------------------------------------------------------------------

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});
  final AudioFile file;

  Color _badgeColor(BuildContext context, OutputFormat fmt) {
    final p = context.peel;
    switch (fmt) {
      case OutputFormat.mp3:
        return p.peel;
      case OutputFormat.m4a:
        return p.groove;
      case OutputFormat.wav:
        return const Color(0xFF4DA6FF);
      case OutputFormat.flac:
        return const Color(0xFFB06FE8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    final badgeColor = _badgeColor(context, file.format);

    return GestureDetector(
      onTap: () {
        Haptics.tap();
        context.read<PlayerProvider>().toggle(
              file.outputAudioPath,
              title: file.outputAudioName,
              subtitle: file.qualityBadge,
            );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: Space.xs),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: p.line, width: 1),
        ),
        child: Row(
          children: [
            // ── Format badge ──────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              alignment: Alignment.center,
              child: Text(
                file.format.label,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
            const SizedBox(width: Space.sm),

            // ── Title + subtitle ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.outputAudioName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Jakarta',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        FormatUtils.duration(file.duration),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: p.inkMuted,
                        ),
                      ),
                      Text(
                        '  ·  ',
                        style: TextStyle(color: p.inkFaint, fontSize: 11),
                      ),
                      Text(
                        FormatUtils.fileSize(file.fileSize),
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: p.inkMuted,
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      _QualityBadge(file: file),
                    ],
                  ),
                ],
              ),
            ),

            // ── More menu ─────────────────────────────────────────────
            IconButton(
              icon: Icon(Icons.more_vert, size: 20, color: p.inkMuted),
              onPressed: () => _showActionSheet(context, file),
              tooltip: 'More options',
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, AudioFile file) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.peel.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Radii.hero),
        ),
      ),
      builder: (_) => _FileActionSheet(file: file),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.file});
  final AudioFile file;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: p.surfaceHi,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Text(
        file.format.lossless
            ? file.format.label
            : '${file.quality.kbps}k',
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.inkMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action Bottom Sheet
// ---------------------------------------------------------------------------

class _FileActionSheet extends StatelessWidget {
  const _FileActionSheet({required this.file});
  final AudioFile file;

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.gutter,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: Space.md),
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
              ),
            ),
            // File name
            Text(
              file.outputAudioName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Jakarta',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            Text(
              '${FormatUtils.duration(file.duration)}  ·  ${FormatUtils.fileSize(file.fileSize)}',
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: p.inkMuted,
              ),
            ),
            const SizedBox(height: Space.md),
            _ActionTile(
              icon: Icons.play_circle_outline,
              label: AppStrings.libraryActionPlay,
              onTap: () {
                Navigator.pop(context);
                context.read<PlayerProvider>().toggle(
                      file.outputAudioPath,
                      title: file.outputAudioName,
                      subtitle: file.qualityBadge,
                    );
              },
            ),
            _ActionTile(
              icon: Icons.share_outlined,
              label: AppStrings.libraryActionShare,
              onTap: () {
                Navigator.pop(context);
                MediaBridge.share([file.outputAudioPath],
                    mime: file.format.mime);
              },
            ),
            _ActionTile(
              icon: Icons.notifications_none_outlined,
              label: AppStrings.libraryActionRingtone,
              onTap: () {
                Navigator.pop(context);
                _setRingtone(context, file);
              },
            ),
            _ActionTile(
              icon: Icons.open_in_new_outlined,
              label: AppStrings.libraryActionOpenWith,
              onTap: () {
                Navigator.pop(context);
                MediaBridge.openWith(file.outputAudioPath,
                    mime: file.format.mime);
              },
            ),
            const Divider(height: Space.lg),
            _ActionTile(
              icon: Icons.delete_outline,
              label: AppStrings.libraryActionDelete,
              color: context.peel.danger,
              onTap: () {
                Navigator.pop(context);
                _delete(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setRingtone(BuildContext context, AudioFile file) async {
    final canWrite = await MediaBridge.canWriteSettings();
    if (!canWrite) {
      await MediaBridge.requestWriteSettings();
      return;
    }
    await MediaBridge.setRingtone(
      file.outputAudioPath,
      RingtoneSlot.ringtone,
    );
  }

  void _delete(BuildContext context, AudioFile file) {
    final history = context.read<HistoryProvider>();
    history.stageDelete(file);

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: const Text(AppStrings.libraryDeletedSnackbar),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: AppStrings.libraryUndoLabel,
              onPressed: () => history.undoDelete(file),
            ),
          ),
        )
        .closed
        .then((reason) {
      if (reason != SnackBarClosedReason.action) {
        history.commitDelete(file);
      }
    });
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
        padding: const EdgeInsets.symmetric(
          vertical: Space.sm,
          horizontal: Space.xs,
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 22),
            const SizedBox(width: Space.md),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Jakarta',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = context.peel;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.headphones, size: 64, color: p.groove.withValues(alpha: 0.5)),
          const SizedBox(height: Space.md),
          Text(
            AppStrings.libraryEmptyTitle,
            style: TextStyle(
              fontFamily: 'Jakarta',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            AppStrings.libraryEmptySubtitle,
            style: TextStyle(
              fontFamily: 'Jakarta',
              fontSize: 14,
              color: p.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
