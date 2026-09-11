import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Чип-пилюля + список, который вырастает вниз из самой пилюли
/// (AnimatedSize), а не накладывается поверх контента.
/// [maxListHeight] != null => включается мягкий скролл списка.
class PillMenu extends StatelessWidget {
  const PillMenu({
    required this.value,
    required this.options,
    required this.open,
    required this.onToggle,
    required this.onPick,
    this.icon,
    this.maxListHeight,
    super.key,
  });

  final String? value;
  final Map<String, String> options; // value -> label
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;
  final IconData? icon;
  final double? maxListHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label =
        value == null ? '—' : (options[value] ?? value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppTheme.animDuration,
              curve: AppTheme.animCurve,
              padding: EdgeInsets.symmetric(
                  horizontal: icon != null ? 13 : 14, vertical: 11),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: theme.colorScheme.secondary),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppTheme.animDuration,
                    curve: AppTheme.animCurve,
                    child: Icon(Icons.arrow_drop_down_rounded,
                        size: 20, color: theme.colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Список вырастает из пилюли вниз:
        AnimatedSize(
          duration: AppTheme.animDuration,
          curve: AppTheme.animCurve,
          alignment: Alignment.topCenter,
          child: open ? _list(context, theme) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _list(BuildContext context, ThemeData theme) {
    Widget col = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in options.entries)
          _OptionRow(
            label: e.value,
            selected: e.key == value,
            onTap: () => onPick(e.key),
          ),
      ],
    );

    if (maxListHeight != null) {
      col = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight!),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // мягкий скролл
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: col,
          ),
        ),
      );
    } else {
      col = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: col,
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16), // такие же скругления
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: col,
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.animDuration,
          curve: AppTheme.animCurve,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_rounded,
                    size: 14, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}