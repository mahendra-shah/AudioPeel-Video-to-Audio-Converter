import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// A reusable branded audio icon widget that displays the AudioPeel logo
/// instead of generic Material Icons.
///
/// Supports customization of size, color, container style, and optional
/// animations for use throughout the app in place of Icons.music_note_rounded.
///
/// Features:
/// - Image asset with fallback to Material Icon if loading fails
/// - Optional color tinting via ColorFilter
/// - Circular or rounded-square container shapes
/// - Optional pulse/rotation animations
/// - Consistent sizing and styling
///
/// Example usage:
/// ```dart
/// AudioIcon(size: 22, color: AppColors.primary)
/// AudioIcon(size: 48, shape: BoxShape.circle, animate: true)
/// AudioIcon(size: 28, borderRadius: BorderRadius.circular(8))
/// ```
class AudioIcon extends StatefulWidget {
  const AudioIcon({
    super.key,
    this.size = 22,
    this.color,
    this.backgroundColor,
    this.shape,
    this.borderRadius,
    this.animate = false,
    this.showContainer = true,
  });

  /// Size of the icon in logical pixels (applies to both width and height)
  final double size;

  /// Optional color filter to tint the icon (useful for theme consistency)
  final Color? color;

  /// Optional background color for the container
  final Color? backgroundColor;

  /// Container shape - null uses borderRadius, BoxShape.circle for circular
  final BoxShape? shape;

  /// Border radius for rounded rectangle containers (ignored if shape is circle)
  final BorderRadius? borderRadius;

  /// Whether to animate the icon (pulse scale or rotation)
  final bool animate;

  /// Whether to wrap icon in a container with background
  final bool showContainer;

  @override
  State<AudioIcon> createState() => _AudioIconState();
}

class _AudioIconState extends State<AudioIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      )..repeat(reverse: true);
      _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Material icon directly — the PNG asset (audio_icon.png) has an opaque
    // background which causes BlendMode.srcIn to render as a solid colour block.
    // Icons.music_note_rounded is crisp, scales perfectly, and needs no asset.
    Widget icon = Icon(
      Icons.music_note_rounded,
      size: widget.size,
      color: widget.color ?? AppColors.primary,
    );

    // Apply animation if requested
    if (widget.animate) {
      icon = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: icon,
      );
    }

    // Optionally wrap in container with background
    if (widget.showContainer) {
      final containerColor = widget.backgroundColor ??
          (widget.color ?? AppColors.primary).withValues(alpha: 0.15);

      final containerSize = widget.size * 2.2; // Container ~2.2x icon size

      return Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: containerColor,
          shape: widget.shape ?? BoxShape.rectangle,
          borderRadius:
              widget.shape == BoxShape.circle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
        ),
        child: Center(child: icon),
      );
    }

    return icon;
  }
}
