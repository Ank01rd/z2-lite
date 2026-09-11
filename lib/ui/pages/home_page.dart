import 'package:flutter/material.dart';

import '../../core/app_localization.dart';
import '../../core/lite_settings.dart';
import '../../services/zapret_service.dart';
import '../widgets/config_drop.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/snack.dart';
import '../widgets/progress_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.settings, super.key});

  final LiteSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _cardKey = GlobalKey();

  double _panelMaxHeight(BuildContext pillContext) {
    final cardCtx = _cardKey.currentContext;
    if (cardCtx == null) return 220;
    final cardBox = cardCtx.findRenderObject()! as RenderBox;
    final pillBox = pillContext.findRenderObject()! as RenderBox;
    final cardBottom =
        cardBox.localToGlobal(Offset(0, cardBox.size.height)).dy;
    final pillBottom =
        pillBox.localToGlobal(Offset(0, pillBox.size.height)).dy;
    return (cardBottom - pillBottom - 4).clamp(96.0, 400.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 404),
        child: Container(
          key: _cardKey,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ListenableBuilder(
            listenable:
                Listenable.merge([ZapretService.instance, widget.settings]),
            builder: (context, _) {
              final svc = ZapretService.instance;
              final configs = svc.configs;
              final cfg = configs.contains(widget.settings.selectedConfig)
                  ? widget.settings.selectedConfig
                  : (configs.isNotEmpty ? configs.first : null);

              return Column(
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
                        child: Icon(Icons.tune_rounded,
                            size: 17, color: theme.colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 10),
                      Text(Loc.t('configuration'),
                          style: theme.textTheme.bodyLarge),
                      const Spacer(),
                      Tooltip(
                        message: Loc.t('tooltipIpset'),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: svc.busy
                              ? null
                              : () async {
                                  final msg =
                                      await svc.updateIpset(svc.zapretDir);
                                  await svc.refresh();
                                  if (context.mounted) {
                                    showSnack(context, msg);
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(Icons.cloud_sync_rounded,
                                size: 16, color: theme.colorScheme.secondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── кнопка «Скачать Zapret», если конфигов нет ──
                  configs.isEmpty
                      ? FilledButton.icon(
                          onPressed: svc.busy
                              ? null
                              : () async {
                                  final msg = await runWithProgress(
                                    context,
                                    title: Loc.t('downloadZapret'),
                                    icon: Icons.download_rounded,
                                    task: (onProgress) => svc.downloadZapret(
                                        svc.zapretDir, onProgress: onProgress),
                                  );
                                  if (context.mounted) {
                                    showSnack(context, msg);
                                  }
                                },
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(Loc.t('downloadZapret')),
                        )
                      : ConfigDropButton(
                          settings: widget.settings,
                          configs: configs,
                          value: cfg,
                          maxPanelHeightProvider: _panelMaxHeight,
                        ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (svc.busy || cfg == null || svc.running)
                              ? null
                              : () async {
                                  final msg = await svc.start(cfg);
                                  if (context.mounted) showSnack(context, msg);
                                },
                          child: Text(Loc.t('start')),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (svc.busy || !svc.running)
                              ? null
                              : () async {
                                  final msg = await svc.stop();
                                  if (context.mounted) showSnack(context, msg);
                                },
                          child: Text(Loc.t('stop')),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (svc.busy || cfg == null)
                              ? null
                              : () async {
                                  final msg = await svc.restart(cfg);
                                  if (context.mounted) showSnack(context, msg);
                                },
                          child: Text(Loc.t('restart')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: theme.dividerColor),
                  const SizedBox(height: 12),
                  _filterBlock(
                    context,
                    Loc.t('gameFilter'),
                    [
                      Loc.mode('disabled'),
                      Loc.mode('all'),
                      Loc.mode('tcp'),
                      Loc.mode('udp'),
                    ],
                    const ['disabled', 'all', 'tcp', 'udp'],
                    svc.gameFilter,
                    (m) async {
                      final msg = await svc.setGameFilterMode(m);
                      if (context.mounted) showSnack(context, msg);
                    },
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: theme.dividerColor),
                  const SizedBox(height: 12),
                  _filterBlock(
                    context,
                    Loc.t('ipsetFilter'),
                    [
                      Loc.mode('loaded'),
                      Loc.mode('none'),
                      Loc.mode('any'),
                    ],
                    const ['loaded', 'none', 'any'],
                    svc.ipsetStatus,
                    (t) async {
                      final msg = await svc.setIpsetFilter(t);
                      if (context.mounted) showSnack(context, msg);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _filterBlock(
    BuildContext context,
    String title,
    List<String> labels,
    List<String> values,
    String current,
    Future<void> Function(String) onPick,
  ) {
    final theme = Theme.of(context);
    final idx = values.indexOf(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11.5, color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 5),
        SegmentedPill(
          labels: labels,
          selectedIndex: idx < 0 ? 0 : idx,
          onChanged: (i) => onPick(values[i]),
        ),
      ],
    );
  }
}