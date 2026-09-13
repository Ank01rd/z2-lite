import '../../services/zapret_service.dart';
import '../core/maya_result.dart';

class MayaUpdateEngine {
  MayaUpdateEngine({ZapretService? zapret})
      : _zapret = zapret ?? ZapretService.instance;

  final ZapretService _zapret;

  Future<bool> isZapretUpdateAvailable() =>
      _zapret.isZapretUpdateAvailable();

  Future<MayaResult<String>> checkZapret() async {
    try {
      return MayaSuccess(await _zapret.checkZapretUpdate());
    } catch (e) {
      return MayaFailure('Zapret update check failed: $e', error: e);
    }
  }

  Future<String?> checkAppTag() => _zapret.checkAppUpdateTag();

  Future<MayaResult<String>> installApp({
    void Function(double? p, String stage)? onProgress,
  }) async {
    try {
      return MayaSuccess(await _zapret.installAppUpdate(onProgress: onProgress));
    } catch (e) {
      return MayaFailure('App update failed: $e', error: e);
    }
  }

  Future<MayaResult<String>> downloadZapret({
    required String folder,
    void Function(double? p, String stage)? onProgress,
  }) async {
    try {
      return MayaSuccess(
        await _zapret.downloadZapret(folder, onProgress: onProgress),
      );
    } catch (e) {
      return MayaFailure('Zapret download failed: $e', error: e);
    }
  }

  Future<MayaResult<String>> removeZapretService() async {
    try {
      return MayaSuccess(await _zapret.removeZapretService());
    } catch (e) {
      return MayaFailure('Zapret service removal failed: $e', error: e);
    }
  }
}
