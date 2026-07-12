/// Session lock/suspend state.
abstract interface class SessionSignals {
  /// Emits `true` when the session locks or the system suspends,
  /// `false` when it unlocks/resumes. May emit duplicates.
  Stream<bool> get away;

  Future<void> dispose();
}
