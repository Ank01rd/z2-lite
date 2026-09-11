import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Минималистичный монохромный тумблер без material-синевы.
class MonoSwitch extends StatelessWidget {
  const MonoSwitch({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppTheme.animDuration,
          curve: AppTheme.animCurve,
          width: 38,
          height: 22,
          decoration: BoxDecoration(
            color: value ? theme.colorScheme.primary : theme.colorScheme.outline,
            borderRadius: BorderRadius.circular(11),
          ),
          child: AnimatedAlign(
            duration: AppTheme.animDuration,
            curve: AppTheme.animCurve,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}