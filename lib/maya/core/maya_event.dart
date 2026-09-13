abstract class MayaEvent {
  const MayaEvent();
}

class MayaProtectionStarting extends MayaEvent {
  const MayaProtectionStarting();
}

class MayaProtectionStarted extends MayaEvent {
  const MayaProtectionStarted();
}

class MayaProtectionStopping extends MayaEvent {
  const MayaProtectionStopping();
}

class MayaProtectionStopped extends MayaEvent {
  const MayaProtectionStopped();
}

class MayaProtectionError extends MayaEvent {
  final String message;

  const MayaProtectionError(this.message);
}
