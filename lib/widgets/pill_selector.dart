import 'package:flutter/material.dart';

import '../design/motion.dart';
import '../design/tokens.dart';

/// A horizontal pill/chip row selector with a sliding orange indicator.
///
/// Generic over [T]; uses [label] to convert each item to a display string.
/// Fires [Haptics.select] when a new item is tapped.
class PillSelector<T> extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> items;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.peel;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.surfaceHi,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item == selected;
          return Flexible(
            child: GestureDetector(
              onTap: () {
                if (item == selected) return;
                Haptics.select();
                onChanged(item);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: Motion.short,
                curve: Motion.standard,
                decoration: BoxDecoration(
                  color: isSelected ? c.peel : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                child: AnimatedDefaultTextStyle(
                  duration: Motion.short,
                  curve: Motion.standard,
                  style: (context.text.labelMedium ?? const TextStyle()).copyWith(
                    color: isSelected ? c.onPeel : c.inkMuted,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  child: Text(label(item)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
