import 'package:flutter/material.dart';

import '../design/tokens.dart';

/// A styled surface card with an optional title label above the content.
///
/// Background: [PeelColors.surface], radius: [Radii.card].
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding,
  });

  final Widget child;

  /// Optional label rendered above [child] in a [labelSmall] style.
  final String? title;

  /// Inner padding. Defaults to all-[Space.md].
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;
    final resolvedPadding = padding ?? const EdgeInsets.all(Space.md);

    Widget content = Padding(
      padding: resolvedPadding,
      child: child,
    );

    if (title != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: resolvedPadding.left,
              right: resolvedPadding.right,
              top: resolvedPadding.top,
              bottom: Space.xs,
            ),
            child: Text(
              title!.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: c.inkFaint,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Padding(
            padding: resolvedPadding.copyWith(top: 0),
            child: child,
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: content,
    );
  }
}
