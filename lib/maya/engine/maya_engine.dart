import '../core/maya_event.dart';
import '../core/maya_state.dart';
import 'maya_autostart_engine.dart';
import 'maya_filters_engine.dart';
import 'maya_protection_engine.dart';
import 'maya_update_engine.dart';

class MayaEngine {
  MayaEngine({
    MayaProtectionEngine? protection,
    MayaFiltersEngine? filters,
    MayaAutostartEngine? autostart,
    MayaUpdateEngine? updates,
  })  : protection = protection ?? MayaProtectionEngine(),
        filters = filters ?? MayaFiltersEngine(),
        autostart = autostart ?? MayaAutostartEngine(),
        updates = updates ?? MayaUpdateEngine() {
    this.protection.onEvent = _handleEvent;
    this.protection.onStateChanged = _handleState;
  }

  final MayaProtectionEngine protection;
  final MayaFiltersEngine filters;
  final MayaAutostartEngine autostart;
  final MayaUpdateEngine updates;

  MayaState get state => protection.state;

  void Function(MayaEvent event)? onEvent;
  void Function(MayaState state)? onStateChanged;

  void _handleEvent(MayaEvent event) {
    onEvent?.call(event);
  }

  void _handleState(MayaState state) {
    onStateChanged?.call(state);
  }
}
