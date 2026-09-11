import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Единая пилюля-сегмент: бегунок занимает ровно 1/n ширины
/// и катается через AnimatedAlign — без пиксельной математики
/// и без обрезки краёв (Stack clip: none).
class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const pad = 4.0;
    const h = 34.0;
    final n = labels.length;
    final idx = selectedIndex.clamp(0, n - 1);
    final alignX = n <= 1 ? 0.0 : -1.0 + 2.0 * idx / (n - 1);

    return Container(
      height: h + pad * 2,
      padding: const EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // катающийся бегунок: ровно 1/n ширины, целая высота
          AnimatedAlign(
            duration: AppTheme.animDuration,
            curve: AppTheme.animCurve,
            alignment: Alignment(alignX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              child: SizedBox(
                height: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: SizedBox(
                        height: h,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppTheme.animDuration,
                            curve: AppTheme.animCurve,
                            style: (theme.textTheme.bodySmall ??
                                    const TextStyle())
                                .copyWith(
                              fontSize: 11.5,
                              fontWeight: i == idx
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: i == idx
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.secondary,
                            ),
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}