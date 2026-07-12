import '../models/break_kind.dart';

/// Engine phases. Sealed so consumers must handle every case exhaustively.
sealed class EnginePhase {
  const EnginePhase();
}

/// Timers running; user is working.
class Monitoring extends EnginePhase {
  const Monitoring({required this.nextBreakIn, required this.nextBreakKind});

  final Duration nextBreakIn;
  final BreakKind nextBreakKind;
}

/// Heads-up period: the user has been warned that a break is imminent.
class Warning extends EnginePhase {
  const Warning({required this.kind, required this.startsIn});

  final BreakKind kind;
  final Duration startsIn;
}

/// Break overlay is (or should be) on screen.
class InBreak extends EnginePhase {
  const InBreak({
    required this.kind,
    required this.remaining,
    required this.snoozesLeft,
    required this.strict,
  });

  final BreakKind kind;
  final Duration remaining;
  final int snoozesLeft;

  /// True once the snooze budget is exhausted (or strict-only config).
  final bool strict;
}

/// A due break is being held back because the user is busy (call / DND).
class Deferred extends EnginePhase {
  const Deferred({required this.kind, required this.recheckIn});

  final BreakKind kind;
  final Duration recheckIn;
}

/// Outside work hours, or paused by the user.
class Paused extends EnginePhase {
  const Paused({required this.byUser});

  final bool byUser;
}
