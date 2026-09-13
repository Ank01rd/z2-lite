import '../../services/zapret_service.dart';
import '../core/maya_event.dart';
import '../core/maya_result.dart';
import '../core/maya_state.dart';

class MayaProtectionEngine {
  MayaProtectionEngine({
    ZapretService? zapret,
  }) : _zapret = zapret ?? ZapretService.instance {
    _zapret.addListener(_handleZapretChanged);
  }

  final ZapretService _zapret;

  MayaState _state = const MayaState();

  MayaState get state => _state;
  ZapretService get zapret => _zapret;

  void Function(MayaEvent event)? onEvent;
  void Function(MayaState state)? onStateChanged;

  void _handleZapretChanged() {
    final next = _zapret.running
        ? MayaProtectionState.running
        : _state.protection == MayaProtectionState.starting ||
                _state.protection == MayaProtectionState.stopping
            ? _state.protection
            : MayaProtectionState.stopped;

    if (next != _state.protection) {
      _setState(next);
    }
  }

  void _setState(MayaProtectionState protection) {
    _state = _state.copyWith(protection: protection);
    onStateChanged?.call(_state);
  }

  void _emit(MayaEvent event) {
    onEvent?.call(event);
  }

  Future<MayaResult<String>> start(String configName) async {
    if (_state.protection == MayaProtectionState.starting ||
        _state.protection == MayaProtectionState.running) {
      return const MayaFailure('Protection is already running.');
    }

    _setState(MayaProtectionState.starting);
    _emit(const MayaProtectionStarting());

    try {
      final message = await _zapret.start(configName);
      await _zapret.syncStatus();

      if (_zapret.running) {
        _setState(MayaProtectionState.running);
        _emit(const MayaProtectionStarted());
        return MayaSuccess(message);
      }

      const error = 'Protection failed to start.';
      _setState(MayaProtectionState.error);
      _emit(const MayaProtectionError(error));
      return const MayaFailure(error);
    } catch (e) {
      final message = e.toString();
      _setState(MayaProtectionState.error);
      _emit(MayaProtectionError(message));
      return MayaFailure(message, error: e);
    }
  }

  Future<MayaResult<String>> stop() async {
    if (_state.protection == MayaProtectionState.stopping ||
        _state.protection == MayaProtectionState.stopped) {
      return const MayaSuccess('Protection is already stopped.');
    }

    _setState(MayaProtectionState.stopping);
    _emit(const MayaProtectionStopping());

    try {
      final message = await _zapret.stop();
      await _zapret.syncStatus();

      if (!_zapret.running) {
        _setState(MayaProtectionState.stopped);
        _emit(const MayaProtectionStopped());
        return MayaSuccess(message);
      }

      const error = 'Protection is still running.';
      _setState(MayaProtectionState.error);
      _emit(const MayaProtectionError(error));
      return const MayaFailure(error);
    } catch (e) {
      final message = e.toString();
      _setState(MayaProtectionState.error);
      _emit(MayaProtectionError(message));
      return MayaFailure(message, error: e);
    }
  }

  Future<MayaResult<String>> restart(String configName) async {
    final stopped = await stop();
    if (stopped is MayaFailure<String>) {
      return stopped;
    }
    return start(configName);
  }

  Future<void> refresh() async {
    await _zapret.syncStatus();
    _setState(
      _zapret.running
          ? MayaProtectionState.running
          : MayaProtectionState.stopped,
    );
  }
}
