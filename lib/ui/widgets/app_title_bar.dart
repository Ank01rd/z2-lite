import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/app_theme.dart';

/// Компактный кастомный тайтлбар (44px) с drag-зоной и кнопками окна.
class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => windowManager.startDragging(),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(width: 14),
            Text(
              'Z2 Lite',
              style: TextStyle(
                fontFamily: 'TitleFont', // курсивный Inter из ассетов
                fontStyle: FontStyle.italic,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            _TitleButton(
                icon: Icons.remove_rounded, onTap: windowManager.minimize),
            _TitleButton(
                icon: Icons.close_rounded, onTap: windowManager.close),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _TitleButton extends StatefulWidget {
  const _TitleButton({required this.icon, required this.onTap});

  final IconData icon;
  final Future<void> Function() onTap;

  @override
  State<_TitleButton> createState() => _TitleButtonState();
}

class _TitleButtonState extends State<_TitleButton> {
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
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: _hover ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(widget.icon, size: 16, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}