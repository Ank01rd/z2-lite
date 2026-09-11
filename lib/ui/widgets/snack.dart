import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Тост: плавно выезжает снизу, держится 2 ПОЛНЫЕ секунды
/// (таймер стартует после завершения анимации появления) и плавно уезжает.
void showSnack(BuildContext context, String message) =>
    _ToastHost.show(context, message);

class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.message, required this.onDone, super.key});

  final String message;
  final VoidCallback onDone;

  static const Duration holdDuration = Duration(seconds: 2);

  static OverlayEntry? _entry;

  static void show(BuildContext context, String message) {
    _entry?.remove();
    _entry = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastHost(
        message: message,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Text(
                  widget.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}