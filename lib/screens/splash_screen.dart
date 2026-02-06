import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import 'home_screen.dart';

/// Branded splash screen with concentric animated rings, a central
/// app icon, progress bar, and version number.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final AnimationController _progressController;
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeController.forward();

    // Navigate to Home after a short delay.
    Future.delayed(const Duration(milliseconds: 1500), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: AppConstants.animationDuration,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ringSize = screenSize.width * 1.2;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: FadeTransition(
        opacity: _fadeIn,
        child: Stack(
          children: [
            // ── Concentric animated rings (background) ────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConcentricRingsPainter(
                      animation: _ringController.value,
                      ringCount: 4,
                      maxRadius: ringSize / 2,
                      center: Offset(
                        screenSize.width / 2,
                        screenSize.height * 0.42,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Floating particles ────────────────────────────────
            ..._buildParticles(screenSize),

            // ── Main content ──────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(flex: 3),

                  // ── App Icon ────────────────────────────────────
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5B9BF6), Color(0xFF3B6DE0)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Film strip icon.
                        const Icon(
                          Icons.movie_creation_rounded,
                          color: Colors.white,
                          size: 56,
                        ),
                        // Small music note badge in bottom-right.
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF334155),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── App Name ────────────────────────────────────
                  Text(
                    AppStrings.homeTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Tagline ─────────────────────────────────────
                  Text(
                    AppStrings.appTagline,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Progress Bar ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressController.value,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3B82F6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Version ─────────────────────────────────────
                  Text(
                    'v1.0',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds small floating dot/diamond particles scattered across the
  /// background for visual depth.
  List<Widget> _buildParticles(Size screenSize) {
    // Static positions + sizes for decorative particles.
    final particles = [
      const _Particle(0.15, 0.18, 6, BoxShape.rectangle, 0.4),
      const _Particle(0.82, 0.14, 5, BoxShape.circle, 0.5),
      const _Particle(0.08, 0.55, 4, BoxShape.circle, 0.3),
      const _Particle(0.88, 0.48, 7, BoxShape.rectangle, 0.35),
      const _Particle(0.75, 0.72, 5, BoxShape.circle, 0.25),
      const _Particle(0.22, 0.78, 6, BoxShape.rectangle, 0.3),
      const _Particle(0.55, 0.12, 4, BoxShape.circle, 0.45),
      const _Particle(0.92, 0.32, 5, BoxShape.rectangle, 0.2),
    ];

    return particles.map((p) {
      return Positioned(
        left: screenSize.width * p.x,
        top: screenSize.height * p.y,
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: p.opacity),
              shape: p.shape,
              borderRadius: p.shape == BoxShape.rectangle
                  ? BorderRadius.circular(1.5)
                  : null,
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Decorative particle data.
class _Particle {
  const _Particle(this.x, this.y, this.size, this.shape, this.opacity);

  final double x;
  final double y;
  final double size;
  final BoxShape shape;
  final double opacity;
}

/// Paints concentric ring arcs with subtle animation.
class _ConcentricRingsPainter extends CustomPainter {
  _ConcentricRingsPainter({
    required this.animation,
    required this.ringCount,
    required this.maxRadius,
    required this.center,
  });

  final double animation;
  final int ringCount;
  final double maxRadius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < ringCount; i++) {
      final progress = (i + 1) / ringCount;
      final radius = maxRadius * progress;
      final opacity = 0.08 - (i * 0.015);

      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: opacity.clamp(0.02, 0.1))
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Draw a nearly-full arc that slowly rotates.
      final startAngle = animation * 2 * math.pi * (i.isEven ? 1 : -1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 1.85,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingsPainter oldDelegate) => true;
}
