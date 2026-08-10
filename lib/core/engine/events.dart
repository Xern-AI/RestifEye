// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../models/break_kind.dart';

/// Facts the engine emits as they happen — consumed by the persistence layer
/// (break_events log) and by services (notifications, overlay, exercises).
sealed class EngineEvent {
  const EngineEvent(this.at);

  /// Wall-clock timestamp of the event.
  final DateTime at;
}

class WarningIssued extends EngineEvent {
  const WarningIssued(super.at, this.kind, this.lead);
  final BreakKind kind;
  final Duration lead;
}

class BreakStarted extends EngineEvent {
  const BreakStarted(super.at, this.kind, {required this.strict});
  final BreakKind kind;
  final bool strict;
}

class BreakSnoozed extends EngineEvent {
  const BreakSnoozed(super.at, this.kind, {required this.snoozesLeft});
  final BreakKind kind;
  final int snoozesLeft;
}

/// User skipped the pending break outright from the warning notification.
class BreakSkipped extends EngineEvent {
  const BreakSkipped(super.at, this.kind, {required this.skipsLeft});
  final BreakKind kind;
  final int skipsLeft;
}

class BreakCompleted extends EngineEvent {
  const BreakCompleted(super.at, this.kind);
  final BreakKind kind;
}

/// User used the emergency escape (long-press) during a strict break.
class BreakEscaped extends EngineEvent {
  const BreakEscaped(super.at, this.kind);
  final BreakKind kind;
}

class BreakDeferred extends EngineEvent {
  const BreakDeferred(super.at, this.kind, {required this.totalDeferral});
  final BreakKind kind;
  final Duration totalDeferral;
}

/// The user was away (idle/locked/suspended) long enough that the time
/// counts as a break — no interruption needed.
class BreakCredited extends EngineEvent {
  const BreakCredited(super.at, this.kind, this.outcome, this.awayFor);
  final BreakKind kind;
  final BreakOutcome outcome;
  final Duration awayFor;
}

class EnginePausedByWorkHours extends EngineEvent {
  const EnginePausedByWorkHours(super.at);
}

/// Scheduling is on hold because something on screen must not be
/// interrupted — a fullscreen video, a presentation, a game.
class EnginePausedByMedia extends EngineEvent {
  const EnginePausedByMedia(super.at, {this.byApp});

  /// The app holding the inhibitor, when the desktop tells us. Null is
  /// normal, not an error.
  final String? byApp;
}

class EngineResumed extends EngineEvent {
  const EngineResumed(super.at);
}
