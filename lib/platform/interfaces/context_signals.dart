/// Signals that the user should not be interrupted right now.
abstract interface class ContextSignals {
  /// True when the microphone/camera is in use or Do Not Disturb is on.
  /// Implementations must return `false` on backend errors — never throw.
  Future<bool> isBusy();
}
