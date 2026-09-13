import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../core/lite_settings.dart';
import '../../services/zapret_service.dart';
import '../widgets/app_title_bar.dart';
import '../widgets/nav_pill.dart';
import 'home_page.dart';
import 'settings_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({required this.settings, super.key});
  final LiteSettings settings;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  AppPage _page = AppPage.home;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.settings.darkTheme ? AppTheme.dark() : AppTheme.light();
    return AnimatedTheme(
      data: data,
      duration: AppTheme.animDuration,
      curve: AppTheme.animCurve,
      child: Scaffold(
        body: Column(
          children: [
            const AppTitleBar(),
            Expanded(
              // пилюля прижата к ВЕРХУ слева, контент справа
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 14),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: NavPill(
                        current: _page,
                        onSelect: (p) => setState(() => _page = p)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: AppTheme.animDuration,
                      switchInCurve: AppTheme.animCurve,
                      switchOutCurve: AppTheme.animCurve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.015),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: animation, curve: AppTheme.animCurve)),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [...previous, if (current != null) current],
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_page),
                        child: _page == AppPage.home
                            ? HomePage(settings: widget.settings)
                            : SettingsPage(settings: widget.settings),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            // еле заметная надпись внизу: текст · точка · версия
            Padding(
              padding: const EdgeInsets.only(bottom: 5, top: 2),
              child: Center(
                child: Text(
                  '${Loc.t('footer')} · v${ZapretService.currentAppVersion}',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.3,
                    color: data.colorScheme.secondary.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}