import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import 'shell_screen.dart';

/// Launch / splash screen.
///
/// Shows the AudioPeel logo centred on the canvas background and immediately
/// navigates to [ShellScreen] after the first frame is painted — no artificial
/// delay so the user gets to the app as fast as possible.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Motion.medium,
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Motion.emphasizedDecel);

    // Navigate on the very next frame — zero artificial delay.
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      Motion.sharedAxis(const ShellScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.peel.canvas,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Image.asset(
            'assets/icon/audiopeel-nobg.png',
            width: 120,
            height: 120,
            semanticLabel: 'AudioPeel logo',
          ),
        ),
      ),
    );
  }
}
