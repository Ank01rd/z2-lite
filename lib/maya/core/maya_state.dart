enum MayaProtectionState {
  stopped,
  starting,
  running,
  stopping,
  error,
}

class MayaState {
  final MayaProtectionState protection;

  const MayaState({
    this.protection = MayaProtectionState.stopped,
  });

  bool get isRunning => protection == MayaProtectionState.running;
  bool get isBusy => protection == MayaProtectionState.starting ||
      protection == MayaProtectionState.stopping;

  MayaState copyWith({
    MayaProtectionState? protection,
  }) {
    return MayaState(
      protection: protection ?? this.protection,
    );
  }
}
