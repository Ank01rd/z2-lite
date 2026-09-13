import '../../services/zapret_service.dart';
import '../core/maya_result.dart';

class MayaFiltersEngine {
  MayaFiltersEngine({ZapretService? zapret})
      : _zapret = zapret ?? ZapretService.instance;

  final ZapretService _zapret;

  String get gameFilter => _zapret.gameFilter;
  String get ipsetStatus => _zapret.ipsetStatus;

  Future<MayaResult<String>> setGameFilter(String mode) async {
    try {
      return MayaSuccess(await _zapret.setGameFilterMode(mode));
    } catch (e) {
      return MayaFailure('Game Filter error: $e', error: e);
    }
  }

  Future<MayaResult<String>> setIpsetFilter(String target) async {
    try {
      return MayaSuccess(await _zapret.setIpsetFilter(target));
    } catch (e) {
      return MayaFailure('IPSet error: $e', error: e);
    }
  }

  Future<MayaResult<String>> updateIpset() async {
    try {
      return MayaSuccess(await _zapret.updateIpset(_zapret.zapretDir));
    } catch (e) {
      return MayaFailure('IPSet update error: $e', error: e);
    }
  }
}
