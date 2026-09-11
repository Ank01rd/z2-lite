import 'package:flutter/material.dart';

/// Показывает модальное окно с прогресс-баром на время выполнения [task]
/// и возвращает результат задачи. Окно нельзя закрыть кликом мимо.
Future<String> runWithProgress(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Future<String> Function(
          void Function(double? p, String stage) onProgress)
      task,
}) async {
  final progress = ValueNotifier<double?>(0.0);
  final stage = ValueNotifier<String>('');
  final navigator = Navigator.of(context, rootNavigator: true);

  final dialogFuture = showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (ctx) => _ProgressDialog(
      title: title,
      icon: icon,
      progress: progress,
      stage: stage,
    ),
  );

  final result = await task((p, s) {
    progress.value = p; // null => неопределённый (бегущий) бар
    stage.value = s;
  });

  await Future.delayed(const Duration(milliseconds: 250));
  if (navigator.mounted) navigator.pop();
  await dialogFuture;
  progress.dispose();
  stage.dispose();
  return result;
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({
    required this.title,
    required this.icon,
    required this.progress,
    required this.stage,
  });

  final String title;
  final IconData icon;
  final ValueNotifier<double?> progress;
  final ValueNotifier<String> stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon,
                        size: 17, color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child:
                          Text(title, style: theme.textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double?>(
                valueListenable: progress,
                builder: (context, p, _) => LinearProgressIndicator(
                  value: p,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: theme.dividerColor,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: stage,
                      builder: (context, s, _) => Text(
                        s.isEmpty ? '…' : s,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<double?>(
                    valueListenable: progress,
                    builder: (context, p, _) => Text(
                      p == null ? '' : '${(p * 100).round()}%',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}