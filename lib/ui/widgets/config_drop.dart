import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../core/lite_settings.dart';

/// Мягкий скролл: драг мышью/трекпадом + пружина, без скроллбаров.
ScrollBehavior softScrollBehavior(BuildContext context) =>
    ScrollConfiguration.of(context).copyWith(
      dragDevices: const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      },
      scrollbars: false,
    );

/// Пилюля конфигов: список выезжает из пилюли (слитно, без ступенек),
/// ограничен низом карточки, закрывается кликом по пилюле / мимо / выбором.
/// Анимация: рост панели (easeOutCubic / easeInCubic при закрытии) +
/// лёгкий сдвиг контента вниз + поздний fade — выглядит «выливающимся».
class ConfigDropButton extends StatefulWidget {
  const ConfigDropButton({
    required this.settings,
    required this.configs,
    required this.value,
    this.maxPanelHeightProvider,
    super.key,
  });

  final LiteSettings settings;
  final List<String> configs;
  final String? value;
  final double? Function(BuildContext pillContext)? maxPanelHeightProvider;

  @override
  State<ConfigDropButton> createState() => _ConfigDropButtonState();
}

class _ConfigDropButtonState extends State<ConfigDropButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  bool _overlayPill = false;
  late final AnimationController _ctrl = AnimationController(
      duration: const Duration(milliseconds: 240), vsync: this);
  late final CurvedAnimation _size = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic);
  late final CurvedAnimation _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOut));
  late final CurvedAnimation _slide = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic));

  bool get _open => _entry != null;

  @override
  void dispose() {
    _entry?.remove();
    _size.dispose();
    _fade.dispose();
    _slide.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _openMenu() {
    final box = context.findRenderObject()! as RenderBox;
    final off = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.of(context).size;
    final panelTop = off.dy + box.size.height;
    final fallback = (screen.height - panelTop - 10).clamp(96.0, 600.0);
    final maxH = widget.maxPanelHeightProvider?.call(context) ?? fallback;

    final entry = OverlayEntry(
      builder: (entryCtx) {
        final t = Theme.of(entryCtx);
        final side = BorderSide(color: t.dividerColor);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: off.dx,
              top: off.dy,
              width: box.size.width,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (c2, _) {
                  final fused = _ctrl.value > 0.15;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _close,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 11),
                            decoration: BoxDecoration(
                              color: t.scaffoldBackgroundColor,
                              borderRadius: fused
                                  ? const BorderRadius.vertical(
                                      top: Radius.circular(16))
                                  : BorderRadius.circular(999),
                              border: Border(
                                top: side,
                                left: side,
                                right: side,
                                bottom: fused ? BorderSide.none : side,
                              ),
                            ),
                            child: _row(t, up: fused),
                          ),
                        ),
                      ),
                      SizeTransition(
                        sizeFactor: _size,
                        axisAlignment: -1,
                        child: FadeTransition(
                          opacity: _fade,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.06),
                              end: Offset.zero,
                            ).animate(_slide),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: maxH),
                              child: _panel(entryCtx),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(entry);
    _entry = entry;
    setState(() => _overlayPill = true);
    _ctrl.forward(from: 0);
  }

  void _close() {
    final e = _entry;
    if (e == null) return;
    _entry = null;
    _ctrl.reverse(from: 1).then((_) {
      e.remove();
      if (mounted) setState(() => _overlayPill = false);
    });
  }

  Widget _row(ThemeData t, {required bool up}) => Row(
        children: [
          Icon(Icons.tune_rounded, size: 16, color: t.colorScheme.secondary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              widget.value ?? Loc.t('noConfigsPath'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            size: 20,
            color: t.colorScheme.secondary,
          ),
        ],
      );

  Widget _panel(BuildContext ctx) {
    final t = Theme.of(ctx);
    return Container(
      decoration: BoxDecoration(
        color: t.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          left: BorderSide(color: t.dividerColor),
          right: BorderSide(color: t.dividerColor),
          bottom: BorderSide(color: t.dividerColor),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: widget.configs.isEmpty
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Text(Loc.t('noConfigs'),
                  style: t.textTheme.bodySmall
                      ?.copyWith(color: t.colorScheme.secondary)),
            )
          : ScrollConfiguration(
              behavior: softScrollBehavior(ctx),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final name in widget.configs)
                      _ConfigRow(
                        name: name,
                        selected: name == widget.value,
                        onTap: () {
                          widget.settings.setSelectedConfig(name);
                          _close();
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final side = BorderSide(color: theme.dividerColor);
    return Opacity(
      opacity: _overlayPill ? 0 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _open ? _close : _openMenu,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border(top: side, left: side, right: side, bottom: side),
            ),
            child: _row(theme, up: false),
          ),
        ),
      ),
    );
  }
}

class _ConfigRow extends StatefulWidget {
  const _ConfigRow({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ConfigRow> createState() => _ConfigRowState();
}

class _ConfigRowState extends State<_ConfigRow> {
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
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hover ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppTheme.animDuration,
                curve: AppTheme.animCurve,
                width: 16,
                height: 16,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: widget.selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.secondary),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}