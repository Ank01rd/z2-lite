import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_localization.dart';
import '../../core/app_theme.dart';

/// Тост-уведомление: снизу выезжает окно с заголовком «Уведомление»
/// (иконка + подпись в верхней строке) и текстом сообщения ниже.
/// Держится 2 ПОЛНЫЕ секунды после завершения анимации появления.
/// Свою иконку: showSnack(context, msg, icon: Icons.download_rounded)
void showSnack(BuildContext context, String message, {IconData? icon}) =>
    _ToastHost.show(context, message, icon ?? Icons.info_outline_rounded);

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.icon,
    required this.onDone,
    super.key,
  });
  final String message;
  final IconData icon;
  final VoidCallback onDone;

  static const Duration holdDuration = Duration(seconds: 2);
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message, IconData icon) {
    _entry?.remove();
    _entry = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        message: message,
        icon: icon,
        onDone: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      duration: const Duration(milliseconds: 240), vsync: this);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl.forward().then((_) {
      if (!mounted) return;
      _timer = Timer(_ToastHost.holdDuration, _dismiss);
    });
  }

  void _dismiss() {
    _timer?.cancel();
    _ctrl.reverse().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 14,
      child: IgnorePointer(
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1.6), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: _ctrl,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 11),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // строка заголовка: иконка + «Уведомление»
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon,
                            size: 15, color: theme.colorScheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          Loc.t('notification'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}