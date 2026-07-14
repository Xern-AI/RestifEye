import 'dart:async';

import '../clock.dart';
import '../models/break_config.dart';
import '../models/break_kind.dart';
import 'events.dart';
import 'phase.dart';
import 'snapshot.dart';

/// Platform state sampled once per tick (~1 Hz).
class TickInput {
  const TickInput({
    this.idle = Duration.zero,
    this.locked = false,
    this.busy = false,
  });

  /// Time since the last user input.
  final Duration idle;

  /// Session locked or system suspended.
  final bool locked;

  /// Microphone/camera in use, or Do Not Disturb enabled.
  final bool busy;
}

/// Deterministic break scheduler. Pure Dart: no timers, no I/O — the caller
/// drives it with [tick] and it reacts through [phase]/[phases]/[events].
///
/// Scheduling uses the monotonic clock only; wall time is used solely for
/// work-hours checks and event timestamps.
class BreakEngine {
  BreakEngine({
    required this._clock,
    required this._config,
    EngineSnapshot? restoreFrom,
  }) {
    final now = _clock.elapsed();
    // Budgets are per-cycle and deliberately not persisted, so they must be
    // seeded on *every* construction path. Leaving them at zero on restore
    // made the first break after each login strict (and stripped Snooze from
    // its notification), because `_strictNow = _snoozesLeft <= 0 && strict`.
    _snoozesLeft = _config.snoozeBudget;
    _consecutiveSkips = 0;
    if (restoreFrom != null) {
      final gap = _clock.now().difference(restoreFrom.savedAt);
      if (gap >= _config.longDuration) {
        // The app was gone long enough to count as a full break.
        _resetDue(BreakKind.micro, from: now);
        _resetDue(BreakKind.long, from: now);
      } else {
        _microDue = now + restoreFrom.microRemaining - gap;
        _longDue = now + restoreFrom.longRemaining - gap;
      }
    } else {
      _resetDue(BreakKind.micro, from: now);
      _resetDue(BreakKind.long, from: now);
    }
  }

  /// Lead time for the (re-)warning after a deferral or an away return.
  static const Duration _shortLead = Duration(seconds: 15);

  final Clock _clock;
  BreakConfig _config;

  final _phaseController = StreamController<EnginePhase>.broadcast(sync: true);
  final _eventController = StreamController<EngineEvent>.broadcast(sync: true);

  _Mode _mode = _Mode.monitoring;
  late Duration _microDue;
  late Duration _longDue;

  BreakKind _activeKind = BreakKind.micro;
  Duration _breakEndsAt = Duration.zero;
  int _snoozesLeft = 0;
  int _consecutiveSkips = 0;
  bool _strictNow = false;

  /// When the current cycle's break actually fires (moves on re-warns).
  Duration _fireAt = Duration.zero;

  /// The cycle's original due time — fixed until the cycle ends, so total
  /// deferral can be measured against it for the defer cap.
  Duration _cycleDue = Duration.zero;

  Duration _deferRecheckAt = Duration.zero;

  Duration? _awayBegan;
  bool _awayWasLocked = false;

  /// Wall-clock moment a timed pause lapses, or null for an open-ended one.
  /// Wall clock, not monotonic, because it must survive suspend and restart:
  /// "pause for 2 hours" means two hours of the user's life, not of uptime.
  DateTime? _pausedUntil;

  /// An away span may never be backdated before this point — the moment the
  /// last break (or pause) ended. Guards against re-crediting time the user
  /// has already been given credit for.
  Duration _awayFloor = Duration.zero;
  bool _pausedByUser = false;
  bool _pausedByHours = false;

  BreakConfig get config => _config;
  Stream<EnginePhase> get phases => _phaseController.stream;
  Stream<EngineEvent> get events => _eventController.stream;

  /// Whether the current break cycle still has snoozes left.
  bool get canSnooze => _snoozesLeft > 0;

  /// Whether the consecutive-skip budget still allows skipping a break.
  bool get canSkip => _consecutiveSkips < _config.skipBudget;

  EnginePhase get phase {
    if (_pausedByUser) {
      return Paused(byUser: true, until: _pausedUntil);
    }
    if (_pausedByHours) return const Paused(byUser: false);
    final now = _clock.elapsed();
    return switch (_mode) {
      _Mode.monitoring => Monitoring(
        nextBreakIn: _clampZero(_nextDue() - now),
        nextBreakKind: _nextKind(),
        microIn: _clampZero(_microDue - now),
        longIn: _clampZero(_longDue - now),
      ),
      _Mode.warning => Warning(
        kind: _activeKind,
        startsIn: _clampZero(_fireAt - now),
      ),
      _Mode.inBreak => InBreak(
        kind: _activeKind,
        remaining: _clampZero(_breakEndsAt - now),
        snoozesLeft: _snoozesLeft,
        strict: _strictNow,
      ),
      _Mode.deferred => Deferred(
        kind: _activeKind,
        recheckIn: _clampZero(_deferRecheckAt - now),
      ),
    };
  }

  /// Advances the state machine. Call ~once per second.
  void tick(TickInput input) {
    // The phase is published on every tick, even while paused: consumers
    // (the window takeover above all) re-derive their state from it, so a
    // silent engine would let them drift out of sync.
    if (_updateUserPause() || _updateWorkHoursPause()) {
      _publishPhase();
      return;
    }

    final now = _clock.elapsed();
    _trackAway(input, now);

    switch (_mode) {
      case _Mode.monitoring:
        if (_isAway(input)) break; // never schedule against an absent user
        final due = _nextDue();
        if (now >= due - _config.warningLead) {
          _activeKind = _nextKind();
          _cycleDue = due;
          _fireAt = due;
          if (input.busy) {
            _defer(now);
          } else {
            _mode = _Mode.warning;
            _emit(
              WarningIssued(_clock.now(), _activeKind, _clampZero(due - now)),
            );
          }
        }

      case _Mode.warning:
        if (_isAway(input)) break; // resolved by away credit on return
        if (now >= _fireAt) {
          // The defer cap overrides busy: a break can only be pushed so far.
          if (input.busy && now - _cycleDue < _config.deferCap) {
            _defer(now);
          } else {
            _startBreak(now);
          }
        }

      case _Mode.deferred:
        if (_isAway(input)) break;
        if (!input.busy || now - _cycleDue >= _config.deferCap) {
          _rewarn(now); // busy ended (or cap hit) — brief heads-up, then break
        } else if (now >= _deferRecheckAt) {
          _defer(now); // still busy: log continued deferral, keep waiting
        }

      case _Mode.inBreak:
        if (now >= _breakEndsAt) {
          _emit(BreakCompleted(_clock.now(), _activeKind));
          _consecutiveSkips = 0;
          _finishCycle(_activeKind, now);
        }
    }
    _publishPhase();
  }

  /// User snoozes from the warning notification or the break overlay.
  /// Returns false when the budget is exhausted (strict mode holds).
  bool snooze() {
    if (_mode != _Mode.warning && _mode != _Mode.inBreak) return false;
    if (_snoozesLeft <= 0) return false;
    _snoozesLeft -= 1;
    final now = _clock.elapsed();
    _setDue(_activeKind, now + _config.snoozeLength);
    _mode = _Mode.monitoring;
    _emit(BreakSnoozed(_clock.now(), _activeKind, snoozesLeft: _snoozesLeft));
    _publishPhase();
    return true;
  }

  /// Emergency escape (long-press) — always available, always logged.
  void escape() {
    if (_mode != _Mode.inBreak) return;
    _emit(BreakEscaped(_clock.now(), _activeKind));
    _finishCycle(_activeKind, _clock.elapsed());
    _publishPhase();
  }

  /// User starts the due break immediately from the warning.
  void startNow() {
    if (_mode != _Mode.warning) return;
    _startBreak(_clock.elapsed());
    _publishPhase();
  }

  /// User skips the pending break entirely from the warning notification.
  /// Returns false when [BreakConfig.skipBudget] consecutive skips are
  /// already spent; the counter resets on a completed or credited break.
  bool skip() {
    if (_mode != _Mode.warning && _mode != _Mode.deferred) return false;
    if (!canSkip) return false;
    _consecutiveSkips += 1;
    _emit(
      BreakSkipped(
        _clock.now(),
        _activeKind,
        skipsLeft: _config.skipBudget - _consecutiveSkips,
      ),
    );
    _finishCycle(_activeKind, _clock.elapsed());
    _publishPhase();
    return true;
  }

  /// Pauses breaks. [until] is a wall-clock deadline after which the engine
  /// resumes on its own; null pauses open-endedly.
  ///
  /// A pause that never lapses is how a break reminder quietly dies: silenced
  /// before a meeting, forgotten, never resumed. Timed pauses are the default
  /// in the UI for exactly that reason.
  void setPausedByUser(bool paused, {DateTime? until}) {
    if (paused) _abandonBreak();
    _pausedByUser = paused;
    _pausedUntil = paused ? until : null;
    if (!paused) {
      final now = _clock.elapsed();
      _resetDue(BreakKind.micro, from: now);
      _resetDue(BreakKind.long, from: now);
      _mode = _Mode.monitoring;
      // Time spent paused is not rest to be credited.
      _awayFloor = now;
      _awayBegan = null;
      _awayWasLocked = false;
      _emit(EngineResumed(_clock.now()));
    }
    _publishPhase();
  }

  /// When the current timed pause lapses, or null if there is no deadline.
  DateTime? get pausedUntil => _pausedUntil;

  /// Resumes if a timed pause has run its course. Returns true while the
  /// engine remains paused by the user.
  bool _updateUserPause() {
    if (!_pausedByUser) return false;
    final until = _pausedUntil;
    if (until == null || _clock.now().isBefore(until)) return true;
    setPausedByUser(false);
    return false;
  }

  /// Applies new settings. Timers restart from now — predictable and simple.
  void updateConfig(BreakConfig config) {
    _config = config;
    final now = _clock.elapsed();
    _resetDue(BreakKind.micro, from: now);
    _resetDue(BreakKind.long, from: now);
    if (_mode != _Mode.inBreak) _mode = _Mode.monitoring;
    _publishPhase();
  }

  EngineSnapshot snapshot() {
    final now = _clock.elapsed();
    return EngineSnapshot(
      savedAt: _clock.now(),
      microRemaining: _clampZero(_microDue - now),
      longRemaining: _clampZero(_longDue - now),
    );
  }

  void dispose() {
    _phaseController.close();
    _eventController.close();
  }

  // ---- internals -----------------------------------------------------------

  bool _isAway(TickInput input) =>
      input.locked || input.idle >= _config.idleFireThreshold;

  /// Short heads-up before a break that was delayed (deferral or absence).
  void _rewarn(Duration now) {
    _fireAt = now + _shortLead;
    _mode = _Mode.warning;
    _emit(WarningIssued(_clock.now(), _activeKind, _shortLead));
  }

  void _trackAway(TickInput input, Duration now) {
    // A break *is* the rest, so being away during one is the whole point —
    // it is not a separate away span. Tracking it here used to credit the
    // same rest twice and, far worse, end the cycle from *inside* the break:
    // `_resolveAwaySpan` finished the cycle, so the `inBreak` case below
    // never ran, `BreakCompleted` never fired, and nothing ever told the
    // window to leave full-screen — trapping the user in an undecorated,
    // always-on-top window they could not close.
    if (_mode == _Mode.inBreak) {
      _awayBegan = null;
      _awayWasLocked = false;
      return;
    }
    if (_isAway(input)) {
      // Idle time started accumulating before it crossed the threshold —
      // backdate the span start for input-idle (but not for lock).
      //
      // Clamped to _awayFloor: the reported idle time runs straight through
      // any break the user just sat out, so an unclamped backdate would
      // measure the break itself as a fresh away span and credit a second
      // break the moment they touched the keyboard again.
      _awayBegan ??= input.locked
          ? now
          : _laterOf(now - input.idle, _awayFloor);
      _awayWasLocked = _awayWasLocked || input.locked;
      return;
    }
    final began = _awayBegan;
    if (began == null) return;
    final wasLocked = _awayWasLocked;
    _awayBegan = null;
    _awayWasLocked = false;
    _resolveAwaySpan(now - began, now, wasLocked: wasLocked);
  }

  void _resolveAwaySpan(
    Duration span,
    Duration now, {
    required bool wasLocked,
  }) {
    final outcome = wasLocked
        ? BreakOutcome.creditedLock
        : BreakOutcome.creditedIdle;
    if (span >= _config.longDuration) {
      _emit(BreakCredited(_clock.now(), BreakKind.long, outcome, span));
      _consecutiveSkips = 0;
      _finishCycle(BreakKind.long, now);
      return;
    }
    if (span >= _config.idleFireThreshold) {
      _emit(BreakCredited(_clock.now(), BreakKind.micro, outcome, span));
      _consecutiveSkips = 0;
      _finishCycle(BreakKind.micro, now);
      return;
    }
    // Span too short to credit. If a break came due during the absence,
    // give a short warning on return instead of seizing the screen cold.
    final cyclePending = _mode == _Mode.warning || _mode == _Mode.deferred;
    if (cyclePending && now >= _fireAt) {
      _rewarn(now);
    } else if (_mode == _Mode.monitoring && now >= _nextDue()) {
      _setDue(_nextKind(), now + _shortLead);
    }
  }

  /// Ends a break that is on screen when the engine stops running it
  /// (user pause, work window closing). Without this the mode would stay
  /// `inBreak` while `tick` returns early, so no completion event would ever
  /// fire and the break overlay would never be told to stand down.
  void _abandonBreak() {
    if (_mode != _Mode.inBreak) return;
    _emit(BreakEscaped(_clock.now(), _activeKind));
    _finishCycle(_activeKind, _clock.elapsed());
  }

  bool _updateWorkHoursPause() {
    final within = _config.isWithinWorkHours(_clock.now());
    if (!within && !_pausedByHours) {
      _abandonBreak();
      _pausedByHours = true;
      _emit(EnginePausedByWorkHours(_clock.now()));
      _publishPhase();
    } else if (within && _pausedByHours) {
      _pausedByHours = false;
      final now = _clock.elapsed();
      _resetDue(BreakKind.micro, from: now);
      _resetDue(BreakKind.long, from: now);
      _mode = _Mode.monitoring;
      // Time spent paused is not rest to be credited.
      _awayFloor = now;
      _awayBegan = null;
      _awayWasLocked = false;
      _emit(EngineResumed(_clock.now()));
      _publishPhase();
    }
    return _pausedByHours;
  }

  void _startBreak(Duration now) {
    _mode = _Mode.inBreak;
    _breakEndsAt = now + _config.breakDuration(_activeKind);
    _strictNow = _snoozesLeft <= 0 && _config.strictMode;
    _emit(BreakStarted(_clock.now(), _activeKind, strict: _strictNow));
  }

  void _defer(Duration now) {
    _mode = _Mode.deferred;
    _deferRecheckAt = now + _config.deferRecheck;
    _emit(
      BreakDeferred(
        _clock.now(),
        _activeKind,
        totalDeferral: _clampZero(now - _cycleDue),
      ),
    );
  }

  /// Ends the current break cycle for [kind] and reschedules.
  /// A long break always resets the micro timer too.
  void _finishCycle(BreakKind kind, Duration now) {
    _resetDue(kind, from: now);
    if (kind == BreakKind.long) _resetDue(BreakKind.micro, from: now);
    _mode = _Mode.monitoring;
    _snoozesLeft = _config.snoozeBudget;
    _strictNow = false;
    // Rest up to this point is settled; nothing before it may be credited
    // again.
    _awayFloor = now;
    _awayBegan = null;
    _awayWasLocked = false;
  }

  static Duration _laterOf(Duration a, Duration b) => a > b ? a : b;

  /// If both breaks fall due within this window, the long one absorbs the
  /// micro one (nobody wants an eye break two minutes before a long break).
  static const Duration _mergeWindow = Duration(minutes: 2);

  BreakKind _nextKind() =>
      _longDue <= _microDue + _mergeWindow ? BreakKind.long : BreakKind.micro;

  Duration _nextDue() => _nextKind() == BreakKind.long ? _longDue : _microDue;

  void _resetDue(BreakKind kind, {required Duration from}) {
    _setDue(kind, from + _config.interval(kind));
    if (kind == BreakKind.micro) _snoozesLeft = _config.snoozeBudget;
  }

  void _setDue(BreakKind kind, Duration due) {
    if (kind == BreakKind.micro) {
      _microDue = due;
    } else {
      _longDue = due;
    }
  }

  void _emit(EngineEvent event) {
    if (!_eventController.isClosed) _eventController.add(event);
  }

  void _publishPhase() {
    if (!_phaseController.isClosed) _phaseController.add(phase);
  }

  static Duration _clampZero(Duration d) => d.isNegative ? Duration.zero : d;
}

enum _Mode { monitoring, warning, deferred, inBreak }
