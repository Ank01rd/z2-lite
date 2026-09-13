import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_localization.dart';
import '../../core/app_theme.dart';
import '../../core/lite_settings.dart';
import '../../core/windows_autostart.dart';
import '../../services/zapret_service.dart';
import '../widgets/github_icon.dart';
import '../widgets/mono_switch.dart';
import '../widgets/progress_dialog.dart';
import '../widgets/snack.dart';
import '../widgets/telegram_icon.dart';

const Color _danger = Color(0xFFE5484D);

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.settings, super.key});
  final LiteSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 404),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([ZapretService.instance, settings]),
            builder: (context, _) {
              final svc = ZapretService.instance;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SwitchRow(
                      icon: Icons.dark_mode_rounded,
                      title: Loc.t('darkTheme'),
                      value: settings.darkTheme,
                      onChanged: (v) => settings.setDarkTheme(v),
                    ),
                    _divider(context),
                    _SwitchRow(
                      icon: Icons.power_settings_new_rounded,
                      title: Loc.t('launchWindows'),
                      value: settings.launchWithWindows,
                      onChanged: (v) async {
                        await settings.setLaunchWithWindows(v);
                        await WindowsAutostart.setEnabled(v);
                      },
                    ),
                    _divider(context),
                    _SwitchRow(
                      icon: Icons.bolt_rounded,
                      title: Loc.t('zapretAutostart'),
                      value: settings.zapretAutostart,
                      onChanged: (v) async {
                        await settings.setZapretAutostart(v);
                        String? cfg =
                            svc.configs.contains(settings.selectedConfig)
                                ? settings.selectedConfig
                                : null;
                        cfg ??= svc.configs.any((c) =>
                                c.toLowerCase().contains('general (alt)'))
                            ? svc.configs.firstWhere((c) =>
                                c.toLowerCase().contains('general (alt)'))
                            : (svc.configs.isNotEmpty
                                ? svc.configs.first
                                : null);
                        String msg;
                        if (v) {
                          if (cfg == null) {
                            msg = Loc.t('msgNoConfigs');
                          } else {
                            final ok = await WindowsAutostart.installZapret(
                                folder: svc.zapretDir, config: cfg);
                            msg = ok
                                ? '${Loc.t('msgAutostartSet')}: $cfg'
                                : '${Loc.t('msgError')}: '
                                    '${WindowsAutostart.lastError ?? '?'}';
                          }
                        } else {
                          final ok = await WindowsAutostart.removeZapret();
                          msg = ok
                              ? Loc.t('msgAutostartRemoved')
                              : '${Loc.t('msgError')}: '
                                  '${WindowsAutostart.lastError ?? '?'}';
                        }
                        if (context.mounted) showSnack(context, msg);
                      },
                    ),
                    _divider(context),
                    _UpdateRow(
                      icon: Icons.system_update_rounded,
                      title: Loc.t('zapretUpdates'),
                      onPressed: () async {
                        final msg = await svc.checkZapretUpdate();
                        if (context.mounted) showSnack(context, msg);
                      },
                    ),
                    _divider(context),
                    _UpdateRow(
                      icon: Icons.upgrade_rounded,
                      title: Loc.t('appUpdates'),
                      onPressed: () => _checkAndShowUpdateDialog(context),
                    ),
                    _divider(context),
                    _UpdateRow(
                      icon: Icons.download_rounded,
                      title: Loc.t('downloadZapret'),
                      onPressed: () async {
                        final msg = await runWithProgress(
                          context,
                          title: Loc.t('downloadZapret'),
                          icon: Icons.download_rounded,
                          task: (onProgress) => svc.downloadZapret(
                              svc.zapretDir, onProgress: onProgress),
                        );
                        if (context.mounted) showSnack(context, msg);
                      },
                    ),
                    _divider(context),
                    _UpdateRow(
                      icon: Icons.delete_forever_rounded,
                      title: Loc.t('removeService'),
                      color: _danger,
                      onPressed: () => _confirmRemoveService(context),
                    ),
                    _divider(context),
                    Row(
                      children: [
                        Expanded(
                          child: Text(Loc.t('language'),
                              style: theme.textTheme.bodyMedium),
                        ),
                        _LangToggle(
                          current: settings.language,
                          onToggle: () {
                            const order = ['ru', 'en', 'es', 'de'];
                            final i = order.indexOf(settings.language);
                            settings.setLanguage(order[(i + 1) % order.length]);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(Loc.t('pathToZapret'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.secondary)),
                    ),
                    const SizedBox(height: 6),
                    _PathField(svc: svc),
                    const SizedBox(height: 10),
                    // ── три компактные ссылки В ОДНУ СТРОКУ ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LinkButton(
                          tooltip: Loc.t('github'),
                          icon: GithubIcon(
                              size: 14, color: theme.colorScheme.onSurface),
                          label: 'Zapret',
                          url:
                              'https://github.com/Flowseal/zapret-discord-youtube',
                        ),
                        const SizedBox(width: 2),
                        _LinkButton(
                          tooltip: 'GitHub · Z2 Lite',
                          icon: GithubIcon(
                              size: 14, color: theme.colorScheme.onSurface),
                          label: 'Z2 Lite',
                          url:
                              'https://github.com/${ZapretService.appRepo}',
                        ),
                        const SizedBox(width: 2),
                        _LinkButton(
                          tooltip: 'Telegram',
                          icon: TelegramIcon(
                              size: 14, color: theme.colorScheme.onSurface),
                          label: 'Telegram',
                          // ЗАМЕНИ на свой ник Telegram, если другой
                          url: 'https://t.me/Heckazhuk',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemoveService(BuildContext context) async {
    final svc = ZapretService.instance;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Loc.t('removeServiceTitle')),
        content: Text(Loc.t('removeServiceBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Loc.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(Loc.t('remove')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final msg = await svc.removeZapretService();
      if (context.mounted) showSnack(context, msg);
    }
  }

  Future<void> _checkAndShowUpdateDialog(BuildContext context) async {
    final svc = ZapretService.instance;
    final tag = await svc.checkAppUpdateTag();

    if (!context.mounted) return;

    if (tag == null) {
      showSnack(context, Loc.t('msgError'));
      return;
    }

    if (!_isNewerVersion(tag, ZapretService.currentAppVersion)) {
      showSnack(context, Loc.t('otaLatest'));
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(Loc.t('updateAvailable')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${Loc.t('currentVersion')}: ${ZapretService.currentAppVersion}'),
            const SizedBox(height: 4),
            Text('v$tag'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(Loc.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(Loc.t('installUpdate')),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await runWithProgress(
        context,
        title: Loc.t('appUpdates'),
        icon: Icons.upgrade_rounded,
        task: (onProgress) => svc.installAppUpdate(onProgress: onProgress),
      );
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    List<int> parse(String s) => s
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'\D'), '')) ?? 0)
        .toList();
    final a = parse(latest);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  Widget _divider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(
            height: 1, thickness: 1, color: Theme.of(context).dividerColor),
      );
}

/// Компактная кнопка-ссылка: иконка 14 + короткий лейбл, тултип с полным именем.
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.url,
    super.key,
  });
  final String tooltip;
  final Widget icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: TextButton.icon(
        onPressed: () => launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication),
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
        MonoSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _UpdateRow extends StatefulWidget {
  const _UpdateRow({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.color,
    super.key,
  });
  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final Color? color;

  @override
  State<_UpdateRow> createState() => _UpdateRowState();
}

class _UpdateRowState extends State<_UpdateRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.color ?? theme.colorScheme.secondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.animDuration,
          curve: AppTheme.animCurve,
          margin: const EdgeInsets.symmetric(horizontal: -8, vertical: -4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hover
                ? (widget.color ?? theme.colorScheme.onSurface)
                    .withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 17, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: (theme.textTheme.bodyMedium ??
                          const TextStyle(fontSize: 14))
                      .copyWith(
                          color:
                              widget.color ?? theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({
    required this.current,
    required this.onToggle,
    super.key,
  });
  final String current;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Language / Язык / Idioma / Sprache',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language_rounded,
                    size: 14, color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Text(
                  current.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PathField extends StatelessWidget {
  const _PathField({required this.svc});
  final ZapretService svc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              svc.zapretDir,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.secondary),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final dir = await getDirectoryPath();
              if (dir == null) return;
              svc.zapretDir = dir;
              await svc.savePath(dir);
              await svc.refresh();
              if (context.mounted) showSnack(context, Loc.t('pathUpdated'));
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.folder_open_rounded,
                  size: 17, color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}