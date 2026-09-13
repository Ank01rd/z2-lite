import '../../core/windows_autostart.dart';
import '../../services/zapret_service.dart';
import '../core/maya_result.dart';

class MayaAutostartEngine {
  MayaAutostartEngine({ZapretService? zapret})
      : _zapret = zapret ?? ZapretService.instance;

  final ZapretService _zapret;

  Future<bool> isAppEnabled() => WindowsAutostart.isEnabled();

  Future<bool> setAppEnabled(bool enabled) =>
      WindowsAutostart.setEnabled(enabled);

  Future<MayaResult<void>> installZapret({String? config}) async {
    final configs = await _zapret.scanConfigs();
    if (configs.isEmpty) {
      return const MayaFailure('No Zapret configurations found.');
    }

    String selected = configs.first;
    if (config != null && config.trim().isNotEmpty) {
      final lower = config.trim().toLowerCase();
      selected = configs.firstWhere(
        (c) => c.trim().toLowerCase() == lower,
        orElse: () => selected,
      );
    }

    final preferred = configs.where(
      (c) => c.toLowerCase().contains('general (alt)'),
    );
    if ((config == null || !configs.contains(selected)) && preferred.isNotEmpty) {
      selected = preferred.first;
    }

    final ok = await WindowsAutostart.installZapret(
      folder: _zapret.zapretDir,
      config: selected,
    );

    if (!ok) {
      return MayaFailure(
        WindowsAutostart.lastError ?? 'Failed to install Zapret autostart.',
      );
    }

    return MayaSuccess(null);
  }

  Future<MayaResult<void>> removeZapret() async {
    final ok = await WindowsAutostart.removeZapret();
    if (!ok) {
      return MayaFailure(
        WindowsAutostart.lastError ?? 'Failed to remove Zapret autostart.',
      );
    }
    return MayaSuccess(null);
  }

  Future<bool> isZapretEnabled() => WindowsAutostart.isZapretEnabled();
}
