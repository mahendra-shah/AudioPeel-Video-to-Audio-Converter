import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../models/audio_file.dart';
import '../providers/conversion_provider.dart';
import '../providers/history_provider.dart';
import '../services/onboarding_service.dart';
import '../services/ringtone_service.dart';
import '../services/storage_service.dart';
import '../widgets/common/audio_icon.dart';
import '../widgets/common/banner_ad_widget.dart';
import '../widgets/common/recent_conversion_tile.dart';
import 'conversion_options_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// The main home screen — video selection + recent conversions.
///
/// Features a hero graphic with orbiting format badges around a central
/// SELECT button, feature cards (hidden when recents exist), and a
/// recent-conversions section.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AudioFile> _recentFiles = [];
  bool _isLoading = true;
  bool _isPickingVideo = false;

  /// Key for the SELECT VIDEO button — used by the product tour to
  /// highlight it.
  final _selectButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRecentConversions();
    // Re-load recents whenever the history provider changes (e.g. after
    // a deletion on the history screen).
    context.read<HistoryProvider>().addListener(_loadRecentConversions);

    // Show the onboarding product tour on first launch.
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTourIfNeeded());
  }

  @override
  void dispose() {
    context.read<HistoryProvider>().removeListener(_loadRecentConversions);
    super.dispose();
  }

  Future<void> _loadRecentConversions() async {
    final history = context.read<HistoryProvider>();
    final files = await history.recentConversions(limit: 5);
    if (mounted) {
      setState(() {
        _recentFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSelectVideo() async {
    if (_isPickingVideo) return;
    setState(() => _isPickingVideo = true);

    final conversion = context.read<ConversionProvider>();
    final picked = await conversion.selectVideo();

    if (!mounted) return;

    // Only navigate if a NEW video was actually picked (not cancelled).
    if (picked) {
      // Navigate immediately without delay.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ConversionOptionsScreen(),
        ),
      );
      // Refresh recent list when returning from conversion flow.
      if (mounted) _loadRecentConversions();
    }

    if (mounted) setState(() => _isPickingVideo = false);
  }

  void _onSeeAll() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));
  }

  void _onShareFile(AudioFile file) {
    SharePlus.instance.share(ShareParams(files: [XFile(file.outputAudioPath)]));
  }

  void _onPlayFile(AudioFile file) {
    OpenFilex.open(file.outputAudioPath, type: 'audio/mpeg');
  }

  void _confirmDeleteRecent(AudioFile file) {
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
      if (confirmed == true && mounted) {
        await StorageService().deleteFile(file.outputAudioPath);
        if (mounted && file.id != null) {
          context.read<HistoryProvider>().deleteConversion(file.id!);
          // Refresh the recent conversions list.
          _loadRecentConversions();
        }
      }
    });
  }

  Future<void> _onSetRingtone(AudioFile file) async {
    final hasPermission = await RingtoneService.hasWriteSettingsPermission();
    if (!hasPermission) {
      if (!mounted) return;
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
    if (!mounted) return;

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

  // ─── Product Tour ──────────────────────────────────────────────────

  Future<void> _showTourIfNeeded() async {
    final alreadySeen = await OnboardingService.isComplete();
    if (alreadySeen || !mounted) return;

    // Small delay so the hero graphic is fully laid out.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final targets = [
      TargetFocus(
        identify: 'selectVideoButton',
        keyTarget: _selectButtonKey,
        alignSkip: Alignment.bottomCenter,
        enableOverlayTab: true,
        shape: ShapeLightFocus.Circle,
        paddingFocus: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Start Here! 🎬',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap this button to select a video\nand convert it to audio instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '👆 Tap the button above to begin',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primary,
      opacityShadow: 0.85,
      hideSkip: true,
      onClickTarget: (target) {
        // User tapped the SELECT VIDEO button — end tour and start
        // the conversion flow.
        OnboardingService.markComplete();
        _onSelectVideo();
      },
      onFinish: () => OnboardingService.markComplete(),
      onSkip: () {
        OnboardingService.markComplete();
        return true;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final hasRecents = !_isLoading && _recentFiles.isNotEmpty;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _isPickingVideo
          ? const SizedBox.shrink() // Hide content during video selection
          : Column(
              children: [
                // ── Hero Graphic (takes available space) ─────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingScreen,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Hero Graphic with orbiting badges ───────
                        Flexible(
                          child: _HeroOrbitGraphic(
                            compact: hasRecents,
                            onSelect: _onSelectVideo,
                            selectButtonKey: _selectButtonKey,
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingSmall),

                        // ── Subtitle text ──────────────────────────
                        Text(
                          'Tap the button to start converting\nyour videos to audio',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                                height: 1.5,
                              ),
                        ),

                        // ── Feature cards (hidden when recents exist) ──
                        if (!hasRecents) ...[
                          const SizedBox(height: AppConstants.spacingElement),
                          const _FeatureCardsRow(),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Recent conversions (fixed at bottom) ────────
                if (hasRecents) _buildRecentSection(context),

                // Sticky banner ad at the bottom.
                const BannerAdWidget(),
              ],
            ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppConstants.paddingScreen),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icon/audiopeel-nobg.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to branded icon if asset fails to load
                return Container(
                  color: AppColors.primary,
                  child: AudioIcon(
                    size: 18,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      title: Text(
        AppStrings.homeTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ─── Recent Conversions Header ────────────────────────────────────

  Widget _buildRecentSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingScreen,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppConstants.spacingSmall),
          _buildRecentHeader(context),
          const SizedBox(height: AppConstants.spacingSmall),
          _buildRecentList(context),
          const SizedBox(height: AppConstants.spacingSmall),
        ],
      ),
    );
  }

  Widget _buildRecentHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.recentConversions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: _onSeeAll,
          child: Text(
            AppStrings.seeAll,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Recent Conversions List ──────────────────────────────────────

  Widget _buildRecentList(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppConstants.spacingSection),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Show at most 3 recent items — no scrolling.
    final visibleFiles = _recentFiles.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: visibleFiles
          .map(
            (file) => RecentConversionTile(
              key: ValueKey(file.id),
              audioFile: file,
              onTap: () => _onPlayFile(file),
              onShare: () => _onShareFile(file),
              onRingtone: () => _onSetRingtone(file),
              onDelete: () => _confirmDeleteRecent(file),
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Hero Orbit Graphic
// ═══════════════════════════════════════════════════════════════════════

/// Animated hero with concentric rings, a central SELECT button, and
/// four format badges (.MP4, .MOV, .AVI, .MKV) that orbit smoothly.
class _HeroOrbitGraphic extends StatefulWidget {
  const _HeroOrbitGraphic({
    required this.compact,
    required this.onSelect,
    required this.selectButtonKey,
  });

  /// When `true`, the graphic is slightly smaller to leave room for
  /// the recent-conversions section below.
  final bool compact;

  /// Called when the central SELECT button is tapped.
  final VoidCallback onSelect;

  /// GlobalKey for the SELECT button — used for the product tour.
  final GlobalKey selectButtonKey;

  @override
  State<_HeroOrbitGraphic> createState() => _HeroOrbitGraphicState();
}

class _HeroOrbitGraphicState extends State<_HeroOrbitGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Make the graphic fill most of the screen width.
    final screenWidth = MediaQuery.of(context).size.width;
    final size = widget.compact ? screenWidth * 0.78 : screenWidth * 0.88;
    final outerRing = size;
    final middleRing = size * 0.75;
    final innerButton = size * 0.48;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ── Outer dashed ring ────────────────────────
                CustomPaint(
                  size: Size(outerRing, outerRing),
                  painter: _DashedCirclePainter(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    strokeWidth: 1.5,
                    dashLength: 8,
                    gapLength: 5,
                  ),
                ),

                // ── Middle solid ring ────────────────────────
                Container(
                  width: middleRing,
                  height: middleRing,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                ),

                // ── Orbiting format badges ───────────────────
                ..._buildBadges(outerRing / 2),

                // ── Central SELECT VIDEO button ──────────────
                GestureDetector(
                  key: widget.selectButtonKey,
                  onTap: widget.onSelect,
                  child: Container(
                    width: innerButton,
                    height: innerButton,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SELECT VIDEO',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds orbiting format badges at multiple distances with varying
  /// opacity — closer = larger + more opaque, farther = smaller + faint.
  List<Widget> _buildBadges(double orbitRadius) {
    // Inner orbit — primary formats, full opacity, large badges.
    const innerFormats = [
      _OrbitBadgeData('.MP4', Icons.movie_rounded, Color(0xFF6366F1)),
      _OrbitBadgeData('.MOV', Icons.video_file_rounded, AppColors.success),
      _OrbitBadgeData('.AVI', Icons.play_circle_rounded, AppColors.warning),
      _OrbitBadgeData('.MKV', Icons.video_library_rounded, Color(0xFF8B5CF6)),
    ];

    // Middle orbit — secondary formats, medium opacity.
    const midFormats = [
      _OrbitBadgeData('.WEBM', Icons.web_rounded, Color(0xFF0EA5E9)),
      _OrbitBadgeData('.FLV', Icons.slideshow_rounded, Color(0xFFF43F5E)),
      _OrbitBadgeData('.WMV', Icons.ondemand_video_rounded, Color(0xFF14B8A6)),
    ];

    // Outer orbit — rare formats, very low opacity, tiny badges.
    const outerFormats = [
      _OrbitBadgeData('.3GP', Icons.phone_android_rounded, Color(0xFF78716C)),
      _OrbitBadgeData('.TS', Icons.stream_rounded, Color(0xFF6B7280)),
      _OrbitBadgeData('.M4V', Icons.theaters_rounded, Color(0xFF9CA3AF)),
    ];

    const swingAmplitude = 12 * math.pi / 180;

    final List<Widget> badges = [];

    // ── Inner orbit (4 badges, radius 0.92, opacity 0.85, scale 1.0) ──
    for (var i = 0; i < innerFormats.length; i++) {
      final baseAngle = -math.pi * 0.7 + i * (2 * math.pi / 4);
      final direction = i.isEven ? 1.0 : -1.0;
      final angle =
          baseAngle +
          swingAmplitude *
              direction *
              math.sin(_controller.value * 2 * math.pi);

      final dx = orbitRadius * 0.92 * math.cos(angle);
      final dy = orbitRadius * 0.92 * math.sin(angle);

      badges.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: _FormatBadge(
            label: innerFormats[i].label,
            icon: innerFormats[i].icon,
            color: innerFormats[i].color,
            opacity: 0.85,
            scale: 1.0,
          ),
        ),
      );
    }

    // ── Middle orbit (3 badges, radius 0.72, opacity 0.45, scale 0.8) ──
    for (var i = 0; i < midFormats.length; i++) {
      final baseAngle = -math.pi * 0.4 + i * (2 * math.pi / 3);
      final direction = i.isEven ? -1.0 : 1.0;
      final angle =
          baseAngle +
          swingAmplitude *
              0.6 *
              direction *
              math.sin(_controller.value * 2 * math.pi + math.pi / 3);

      final dx = orbitRadius * 0.72 * math.cos(angle);
      final dy = orbitRadius * 0.72 * math.sin(angle);

      badges.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: _FormatBadge(
            label: midFormats[i].label,
            icon: midFormats[i].icon,
            color: midFormats[i].color,
            opacity: 0.45,
            scale: 0.8,
          ),
        ),
      );
    }

    // ── Outer orbit (3 badges, radius 1.08, opacity 0.2, scale 0.65) ──
    for (var i = 0; i < outerFormats.length; i++) {
      final baseAngle = math.pi * 0.1 + i * (2 * math.pi / 3);
      final direction = i.isEven ? 1.0 : -1.0;
      final angle =
          baseAngle +
          swingAmplitude *
              0.4 *
              direction *
              math.sin(_controller.value * 2 * math.pi + math.pi / 1.5);

      final dx = orbitRadius * 1.08 * math.cos(angle);
      final dy = orbitRadius * 1.08 * math.sin(angle);

      badges.add(
        Transform.translate(
          offset: Offset(dx, dy),
          child: _FormatBadge(
            label: outerFormats[i].label,
            icon: outerFormats[i].icon,
            color: outerFormats[i].color,
            opacity: 0.2,
            scale: 0.65,
          ),
        ),
      );
    }

    return badges;
  }
}

/// Data holder for an orbit badge.
class _OrbitBadgeData {
  const _OrbitBadgeData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// A capsule-shaped badge showing a small icon and format extension.
///
/// [opacity] and [scale] control how prominent it appears based on
/// its distance from the centre.
class _FormatBadge extends StatelessWidget {
  const _FormatBadge({
    required this.label,
    required this.icon,
    required this.color,
    this.opacity = 1.0,
    this.scale = 1.0,
  });

  final String label;
  final IconData icon;
  final Color color;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final badgePadH = 10.0 * scale;
    final badgePadV = 6.0 * scale;
    final iconSize = 14.0 * scale;
    final fontSize = 12.0 * scale;

    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: badgePadH,
            vertical: badgePadV,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3 * opacity),
                blurRadius: 12 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              SizedBox(width: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed circle outline.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();
    final dashAngle = dashLength / radius;
    final gapAngle = (2 * math.pi - dashCount * dashAngle) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

// ═══════════════════════════════════════════════════════════════════════
// Feature Cards Row
// ═══════════════════════════════════════════════════════════════════════

/// Three small square-ish feature cards displayed in a row: High Quality,
/// Fast Process, All Formats.
class _FeatureCardsRow extends StatelessWidget {
  const _FeatureCardsRow();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.equalizer_rounded,
        title: 'HIGH\nQUALITY',
        color: AppColors.primary,
      ),
      _FeatureData(
        icon: Icons.bolt_rounded,
        title: 'FAST\nPROCESS',
        color: AppColors.warning,
      ),
      _FeatureData(
        icon: Icons.description_rounded,
        title: 'ALL\nFORMATS',
        color: AppColors.success,
      ),
    ];

    return Row(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        final isLast = index == features.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: _SmallFeatureCard(feature: feature)
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 400),
                )
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 400),
                ),
          ),
        );
      }).toList(),
    );
  }
}

/// Data holder for a small feature card.
class _FeatureData {
  _FeatureData({required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;
}

/// Compact feature card with an icon on top and a two-line label below.
class _SmallFeatureCard extends StatelessWidget {
  const _SmallFeatureCard({required this.feature});

  final _FeatureData feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, color: feature.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
