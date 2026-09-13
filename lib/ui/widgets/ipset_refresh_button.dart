import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class IpsetRefreshButton extends StatefulWidget {
  const IpsetRefreshButton({
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<IpsetRefreshButton> createState() => _IpsetRefreshButtonState();
}

class _IpsetRefreshButtonState extends State<IpsetRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    duration: const Duration(milliseconds: 520),
    vsync: this,
  );
  bool _hover = false;

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  void _tap() {
    if (!widget.enabled || widget.onPressed == null) return;
    _rotation
      ..reset()
      ..forward();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.enabled
        ? theme.colorScheme.secondary
        : theme.colorScheme.secondary.withOpacity(0.35);

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _tap,
        child: AnimatedContainer(
          duration: AppTheme.animDuration,
          curve: AppTheme.animCurve,
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hover && widget.enabled
                ? theme.colorScheme.onSurface.withOpacity(0.055)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hover && widget.enabled
                  ? theme.dividerColor
                  : theme.dividerColor.withOpacity(0.65),
            ),
          ),
          child: RotationTransition(
            turns: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(parent: _rotation, curve: Curves.easeOutCubic),
            ),
            child: Icon(Icons.refresh_rounded, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
