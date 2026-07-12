/// Reports how long the user has been idle (no input).
/// This is the Mac-port seam: implementations exist per platform.
abstract interface class IdleMonitor {
  /// Current idle time. Implementations must return [Duration.zero] on
  /// backend errors rather than throwing — a missed sample must never
  /// stop the engine.
  Future<Duration> currentIdle();

  Future<void> dispose();
}
