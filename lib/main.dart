import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/app_theme.dart';
import 'core/lite_settings.dart';
import 'services/zapret_service.dart';
import 'ui/pages/root_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);

  const windowSize = Size(500, 570);
  await windowManager.setSize(windowSize);
  await windowManager.setMinimumSize(windowSize);
  await windowManager.setMaximumSize(windowSize);
  await windowManager.center();

  final settings = await LiteSettings.load();

  final savedPath = await ZapretService.instance.getSavedPath();
  if (savedPath != null && savedPath.isNotEmpty) {
    ZapretService.instance.zapretDir = savedPath;
  }
  await ZapretService.instance.refresh();

  runApp(Z2LiteApp(settings: settings));

  // Автоматическая проверка обновлений Zapret после запуска UI
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(seconds: 2)); // даём UI отрисоваться
    await _checkZapretUpdateBackground();
  });
}

/// Фоновая проверка обновлений Zapret (без UI, только лог).
/// Если есть обновление — можно добавить системное уведомление.
Future<void> _checkZapretUpdateBackground() async {
  try {
    final hasUpdate = await ZapretService.instance.isZapretUpdateAvailable();
    if (hasUpdate) {
      debugPrint('[Z2] Доступно обновление Zapret');
      // Здесь можно добавить системное уведомление через windows_notification
      // или показать диалог при следующем открытии настроек
    }
  } catch (e) {
    debugPrint('[Z2] Ошибка проверки обновлений: $e');
  }
}

class Z2LiteApp extends StatelessWidget {
  const Z2LiteApp({required this.settings, super.key});

  final LiteSettings settings;

  @override
  Widget build(BuildContext context) {
    // Перестраиваем MaterialApp при изменении настроек: иначе оверлеи
    // и роуты (дропдаун конфигов, диалоги) живут в корневом Overlay ВЫШЕ
    // AnimatedTheme и держат тему, которая была при запуске.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Z2 Lite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
        home: RootPage(settings: settings),
      ),
    );
  }
}