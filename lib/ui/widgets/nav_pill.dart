import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';

enum AppPage { home, settings }

class NavPill extends StatelessWidget {
  const NavPill({required this.current, required this.onSelect, super.key});

  final AppPage current;
  final ValueChanged<AppPage> onSelect;

  static const double _item = 44;
  static const double _gap = 4;
  static const double _pad = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = current == AppPage.home ? 0 : 1;

    return Container(
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SizedBox(
        width: _item,
        height: _item * 2 + _gap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: AppTheme.animDuration,
              curve: AppTheme.animCurve,
              top: idx == 0 ? 0 : _item + _gap,
              left: 0,
              width: _item,
              height: _item,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                _icon(context, AppPage.home, Icons.home_rounded, 0, idx),
                const SizedBox(height: _gap),
                _icon(context, AppPage.settings, Icons.settings_rounded, 1,
                    idx),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(BuildContext context, AppPage page, IconData icon, int i,
      int selected) {
    final theme = Theme.of(context);
    final active = i == selected;
    return SizedBox(
      width: _item,
      height: _item,
      child: Tooltip(
        message:
            page == AppPage.home ? Loc.t('navHome') : Loc.t('navSettings'),
        waitDuration: const Duration(milliseconds: 400),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(page),
            child: TweenAnimationBuilder<Color?>(
              duration: AppTheme.animDuration,
              curve: AppTheme.animCurve,
              tween: ColorTween(
                begin: active
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.secondary,
                end: active
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.secondary,
              ),
              builder: (context, color, _) =>
                  Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}