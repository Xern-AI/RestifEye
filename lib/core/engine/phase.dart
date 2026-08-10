// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

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

/// Why the engine is holding all scheduling.
enum PauseReason {
  /// The user asked for it (indefinitely, or until [Paused.until]).
  user,

  /// The clock is outside the configured work window.
  workHours,

  /// Something on screen must not be interrupted — a fullscreen video, a
  /// presentation, anything holding an idle inhibitor.
  media,
}

/// Outside work hours, paused by the user, or held back for media.
class Paused extends EnginePhase {
  const Paused({required this.reason, this.until, this.byApp});

  final PauseReason reason;

  /// For [PauseReason.media], the app holding breaks back, when the desktop
  /// names it. Null is common and must not be treated as an error.
  final String? byApp;

  /// Wall-clock moment a timed pause lapses and breaks resume by themselves.
  /// Null for an open-ended pause (and always null for the automatic reasons,
  /// which end on their own schedule).
  final DateTime? until;

  /// Only a user pause is reflected in the UI's pause toggle — the automatic
  /// reasons must not make the toggle look switched on.
  bool get byUser => reason == PauseReason.user;
}
