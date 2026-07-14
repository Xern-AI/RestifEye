import '../models/break_kind.dart';

/// Engine phases. Sealed so consumers must handle every case exhaustively.
sealed class EnginePhase {
  const EnginePhase();
}

/// Timers running; user is working.
class Monitoring extends EnginePhase {
  const Monitoring({
    required this.nextBreakIn,
    required this.nextBreakKind,
    required this.microIn,
    required this.longIn,
  });

  final Duration nextBreakIn;
  final BreakKind nextBreakKind;

  /// Independent countdowns for both timers, for the dashboard.
  /// When [nextBreakKind] is long and [microIn] <= [longIn], the micro
  /// break is absorbed by the long one and will not fire separately.
  final Duration microIn;
  final Duration longIn;
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
  const Paused({required this.byUser, this.until});

  final bool byUser;

  /// Wall-clock moment a timed pause lapses and breaks resume by themselves.
  /// Null for an open-ended pause (and always null outside work hours, which
  /// ends on its own schedule).
  final DateTime? until;
}
