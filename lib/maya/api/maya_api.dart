import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/windows_autostart.dart';
import '../../services/zapret_service.dart';
import '../core/maya_event.dart';
import '../core/maya_result.dart';
import '../core/maya_state.dart';
import '../engine/maya_engine.dart';

class MayaApi extends ChangeNotifier {
  MayaApi._() : engine = MayaEngine() {
    _service.addListener(_forwardServiceChange);
    engine.onStateChanged = (_) => notifyListeners();
    engine.onEvent = _events.add;
  }

  static final MayaApi instance = MayaApi._();

  final MayaEngine engine;
  final ZapretService _service = ZapretService.instance;

  static const String appRepo = ZapretService.appRepo;
  static const String currentAppVersion = ZapretService.currentAppVersion;

  Stream<MayaEvent> get events => _events.stream;
  final StreamController<MayaEvent> _events =
      StreamController<MayaEvent>.broadcast();

  MayaState get state => engine.state;
  List<String> get configs => _service.configs;
  bool get running => state.isRunning || _service.running;
  bool get busy => _service.busy || state.isBusy;
  String get gameFilter => engine.filters.gameFilter;
  String get ipsetStatus => engine.filters.ipsetStatus;
  String get zapretDir => _service.zapretDir;
  String? get autostartError => WindowsAutostart.lastError;

  set zapretDir(String path) => _service.zapretDir = path;

  void _forwardServiceChange() => notifyListeners();

  Future<MayaResult<String>> startProtection(String configName) async {
    final result = await engine.protection.start(configName);
    notifyListeners();
    return result;
  }

  Future<MayaResult<String>> stopProtection() async {
    final result = await engine.protection.stop();
    notifyListeners();
    return result;
  }

  Future<MayaResult<String>> restartProtection(String configName) async {
    final result = await engine.protection.restart(configName);
    notifyListeners();
    return result;
  }

  Future<void> refresh() async {
    await engine.protection.refresh();
    notifyListeners();
  }

  Future<String?> getSavedPath() => _service.getSavedPath();
  Future<void> savePath(String path) => _service.savePath(path);

  Future<String> updateIpset(String folder) async {
    final result = await engine.filters.updateIpset();
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String> setGameFilterMode(String mode) async {
    final result = await engine.filters.setGameFilter(mode);
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String> setIpsetFilter(String target) async {
    final result = await engine.filters.setIpsetFilter(target);
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String> downloadZapret(
    String folder, {
    void Function(double? p, String stage)? onProgress,
  }) async {
    final result = await engine.updates.downloadZapret(
      folder: folder,
      onProgress: onProgress,
    );
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String> removeZapretService() async {
    final result = await engine.updates.removeZapretService();
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String> checkZapretUpdate() async {
    final result = await engine.updates.checkZapret();
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<bool> isZapretUpdateAvailable() =>
      engine.updates.isZapretUpdateAvailable();

  Future<String?> checkAppUpdateTag() => engine.updates.checkAppTag();

  Future<String> installAppUpdate({
    void Function(double? p, String stage)? onProgress,
  }) async {
    final result = await engine.updates.installApp(onProgress: onProgress);
    return result is MayaSuccess<String>
        ? result.value
        : (result as MayaFailure<String>).message;
  }

  Future<String?> zapretLocalVersion() => _service.zapretLocalVersion();

  Future<bool> isAppAutostartEnabled() => engine.autostart.isAppEnabled();

  Future<bool> setAppAutostart(bool enabled) =>
      engine.autostart.setAppEnabled(enabled);

  String? get lastAutostartError => WindowsAutostart.lastError;

  Future<bool> installZapretAutostart({
    required String folder,
    required String config,
  }) async {
    _service.zapretDir = folder;
    final result = await engine.autostart.installZapret(config: config);
    return result is MayaSuccess<void>;
  }

  Future<bool> removeZapretAutostart() async {
    final result = await engine.autostart.removeZapret();
    return result is MayaSuccess<void>;
  }

  Future<bool> isZapretAutostartEnabled() =>
      engine.autostart.isZapretEnabled();

}
