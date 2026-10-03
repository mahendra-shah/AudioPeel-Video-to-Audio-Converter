import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../models/media_item.dart';
import '../providers/history_provider.dart';
import '../providers/player_provider.dart';
import '../services/media_bridge.dart';
import '../utils/logger.dart';
import 'batch_studio_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'studio_screen.dart';
import '../widgets/mini_player.dart';

/// Root scaffold: bottom NavigationBar + IndexedStack (tabs stay alive) +
/// a persistent MiniPlayer that slides up above the nav bar when a track
/// is loaded.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  // ── Tabs ──────────────────────────────────────────────────────────────
  int _tabIndex = 0;

  // Each tab has its own navigator so back-stack is preserved per tab.
  final _homeKey = GlobalKey<NavigatorState>();
  final _libraryKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get _activeNavKey =>
      _tabIndex == 0 ? _homeKey : _libraryKey;

  // ── Shared-video stream ───────────────────────────────────────────────
  StreamSubscription<List<String>>? _shareSub;

  // ── Mini-player slide animation ───────────────────────────────────────
  /// Height the mini-player occupies when visible, plus nav bar height.
  static const double _miniPlayerH = 72.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onColdStart());
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  // ── Startup ───────────────────────────────────────────────────────────

  Future<void> _onColdStart() async {
    // Refresh history so the home recent strip is ready.
    if (!mounted) return;
    unawaited(context.read<HistoryProvider>().refresh());

    // Handle cold-start share (app opened via "Share → AudioPeel").
    final initial = await MediaBridge.initialShared();
    if (!mounted) return;
    if (initial.isNotEmpty) {
      await _handleSharedUris(initial);
    }

    // Subscribe to warm-start shares (app already running).
    _shareSub = MediaBridge.sharedUris.listen((uris) {
      if (mounted && uris.isNotEmpty) _handleSharedUris(uris);
    });
  }

  Future<void> _handleSharedUris(List<String> uris) async {
    if (!mounted) return;
    if (uris.length == 1) {
      // Probe the single video then open Studio.
      final item = await _probeWithOverlay(uris.first);
      if (!mounted || item == null) return;
      _homeKey.currentState?.push(Motion.sharedAxis(StudioScreen(media: item)));
    } else {
      // Multiple → batch probe then open BatchStudio.
      final items = await _batchProbeWithOverlay(uris);
      if (!mounted || items.isEmpty) return;
      _homeKey.currentState?.push(
        Motion.sharedAxis(BatchStudioScreen(items: items)),
      );
    }
    // Switch to Convert tab if not already there.
    if (_tabIndex != 0) setState(() => _tabIndex = 0);
  }

  // ── Probe helpers (also used by HomeScreen via navigator key) ─────────

  Future<MediaItem?> _probeWithOverlay(String uri) async {
    if (!mounted) return null;
    _showProbeOverlay();
    try {
      return await MediaBridge.probe(uri);
    } on Exception catch (e) {
      Logger.warning('probe failed: $e', 'ShellScreen');
      return null;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<List<MediaItem>> _batchProbeWithOverlay(List<String> uris) async {
    if (!mounted) return [];
    _showProbeOverlay();
    try {
      final items = <MediaItem>[];
      for (final uri in uris) {
        final item = await MediaBridge.probe(uri);
        if (item != null) items.add(item);
      }
      return items;
    } on Exception catch (e) {
      Logger.warning('batch probe failed: $e', 'ShellScreen');
      return [];
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showProbeOverlay() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProbeOverlay(),
    );
  }

  // ── WillPopScope — intercept Android back inside nested navigators ────

  Future<bool> _onWillPop() async {
    final nav = _activeNavKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final player = context.watch<PlayerProvider>();
    final miniVisible = player.hasTrack;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: c.canvas,
        // IndexedStack keeps both tabs alive.
        body: IndexedStack(
          index: _tabIndex,
          children: [
            _NestedNavigator(
              navigatorKey: _homeKey,
              home: const HomeScreen(),
            ),
            _NestedNavigator(
              navigatorKey: _libraryKey,
              home: const LibraryScreen(),
            ),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mini-player slides in above the nav bar.
            AnimatedSize(
              duration: Motion.medium,
              curve: Motion.emphasizedDecel,
              child: miniVisible
                  ? SizedBox(
                      height: _miniPlayerH,
                      child: MiniPlayer(
                        onTap: () {
                          // Could open a full-screen player; no-op for now.
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            NavigationBar(
              selectedIndex: _tabIndex,
              onDestinationSelected: (i) {
                Haptics.select();
                if (i == _tabIndex) {
                  // Tap same tab: pop to root.
                  _activeNavKey.currentState?.popUntil((r) => r.isFirst);
                } else {
                  setState(() => _tabIndex = i);
                }
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: _tabIndex == 0 ? c.peel : c.inkMuted,
                  ),
                  selectedIcon: Icon(Icons.tune_rounded, color: c.peel),
                  label: 'Convert',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.library_music_outlined,
                    color: _tabIndex == 1 ? c.peel : c.inkMuted,
                  ),
                  selectedIcon: Icon(
                    Icons.library_music_rounded,
                    color: c.peel,
                  ),
                  label: 'Library',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nested navigator widget ─────────────────────────────────────────────────

/// Wraps a [GlobalKey<NavigatorState>] + [home] into a [Navigator] that
/// participates in the [HeroController] context.
class _NestedNavigator extends StatelessWidget {
  const _NestedNavigator({
    required this.navigatorKey,
    required this.home,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => home,
      ),
    );
  }
}

// ── Probe loading overlay ───────────────────────────────────────────────────

class _ProbeOverlay extends StatelessWidget {
  const _ProbeOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.xxl,
          vertical: Space.xl,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.peel, strokeWidth: 3),
            const SizedBox(height: Space.md),
            Text(
              'Reading video…',
              style: context.text.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
