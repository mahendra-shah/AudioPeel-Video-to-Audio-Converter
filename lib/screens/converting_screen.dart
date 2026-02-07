import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/conversion_task.dart';
import '../providers/conversion_provider.dart';
import '../widgets/common/banner_ad_widget.dart';
import 'conversion_error_screen.dart';
import 'conversion_success_screen.dart';

/// Screen shown while FFmpeg is actively converting a video to audio.
///
/// Features:
/// - Beautiful animated circular progress with gradient glow
/// - Dark gradient background
/// - Large percentage display
/// - Poetic status message
/// - Quality/bitrate information
/// - Cancel button
/// - Banner ad at bottom
class ConvertingScreen extends StatefulWidget {
  const ConvertingScreen({super.key});

  @override
  State<ConvertingScreen> createState() => _ConvertingScreenState();
}

class _ConvertingScreenState extends State<ConvertingScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Animation controller for smooth pulsing effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConversionProvider>();
    final task = provider.task;

    // If the conversion finishes, navigate away.
    if (!_hasNavigated && task != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasNavigated) return;

        if (task.status == ConversionStatus.completed) {
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const ConversionSuccessScreen(),
            ),
          );
        } else if (task.status == ConversionStatus.failed) {
          _hasNavigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const ConversionErrorScreen(),
            ),
          );
        } else if (task.status == ConversionStatus.cancelled) {
          _hasNavigated = true;
          Navigator.of(context).pop();
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showCancelDialog,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.appNameAbout,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Options menu could go here
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Animated progress circle
                    _AnimatedProgressCircle(
                      progress: provider.progress,
                      animation: _animationController,
                    ),
                    const SizedBox(height: 40),
                    // Poetic message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Extracting the soul of your video...',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quality and bitrate info
                    _QualityInfoRow(
                      quality: _getQualityLabel(provider.quality.kbps),
                      bitrate: '${provider.quality.kbps}KBPS',
                    ),
                    const SizedBox(height: 60),
                    // Cancel button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _CancelButton(onCancel: _showCancelDialog),
                    ),
                    const SizedBox(height: 24),
                    // Filename
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        task?.inputVideoName ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white38,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Banner ad at the bottom
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  String _getQualityLabel(int kbps) {
    if (kbps >= 320) return 'HIGH FIDELITY';
    if (kbps >= 192) return 'HIGH QUALITY';
    return 'STANDARD';
  }

  /// Shows a confirmation dialog before cancelling the conversion.
  void _showCancelDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.cancelConversion),
        content: const Text(AppStrings.cancelConfirmation),
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
        context.read<ConversionProvider>().cancelConversion();
        // Pop the screen immediately since cancellation may take a moment.
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          Navigator.of(context).pop();
        }
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Animated Progress Circle
// ═══════════════════════════════════════════════════════════════════════

class _AnimatedProgressCircle extends StatelessWidget {
  const _AnimatedProgressCircle({
    required this.progress,
    required this.animation,
  });

  final double progress;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).round();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: 340,
          height: 340,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Outer glow (pulsing)
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.25 + (animation.value * 0.15),
                ),
                blurRadius: 100 + (animation.value * 30),
                spreadRadius: 20,
              ),
              // Inner glow
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.4 + (animation.value * 0.1),
                ),
                blurRadius: 50,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _FilledBlobProgressPainter(
              progress: progress,
              glowIntensity: animation.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large percentage
                  Text(
                    '$percentage%',
                    style: GoogleFonts.poppins(
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 0.9,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status text
                  Text(
                    'RENDERING',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Custom Painter for Filled Blob/Disc Progress with Gradient
// ═══════════════════════════════════════════════════════════════════════

class _FilledBlobProgressPainter extends CustomPainter {
  _FilledBlobProgressPainter({
    required this.progress,
    required this.glowIntensity,
  });

  final double progress;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create radial gradient for the filled circle
    const gradient = RadialGradient(
      colors: [
        Color(0xFF7B3FF2), // Brighter purple center
        AppColors.primary, // Primary purple
        Color(0xFF5E2A9E), // Darker purple edge
      ],
      stops: [0.0, 0.6, 1.0],
    );

    // Draw the filled circle (the blob/disc)
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;

    // Add slight animation wobble to make it feel alive
    final wobble = math.sin(glowIntensity * math.pi * 2) * 3;
    canvas.drawCircle(
      Offset(center.dx + wobble, center.dy),
      radius - 20,
      paint,
    );

    // Add subtle outer ring for depth
    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 20, ringPaint);

    // Add small glowing dots around the perimeter (optional accent)
    final dotCount = 3;
    for (var i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi + glowIntensity * math.pi;
      final dotRadius = radius - 20 + (math.sin(angle * 3) * 8);
      final x = center.dx + dotRadius * math.cos(angle);
      final y = center.dy + dotRadius * math.sin(angle);

      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3 + (glowIntensity * 0.3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), 6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_FilledBlobProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Quality Info Row
// ═══════════════════════════════════════════════════════════════════════

class _QualityInfoRow extends StatelessWidget {
  const _QualityInfoRow({required this.quality, required this.bitrate});

  final String quality;
  final String bitrate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.graphic_eq_rounded, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(
          quality,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        const Text('•', style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(width: 8),
        Text(
          bitrate,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Cancel Button
// ═══════════════════════════════════════════════════════════════════════

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
        ),
        icon: const Icon(Icons.close_rounded, size: 20),
        label: Text(
          AppStrings.cancel.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
