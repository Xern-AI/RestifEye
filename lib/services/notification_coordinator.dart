// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/engine/engine.dart';
import '../core/engine/events.dart';
import '../core/engine/phase.dart';
import '../platform/interfaces/break_notifier.dart';
import '../platform/interfaces/sound_player.dart';

/// Turns engine state into the things the user actually sees and hears — the
/// pre-break warning notification and its sounds — and feeds the
/// notification's actions (Snooze / Start now / Skip) back into the engine.
///
/// Raising a warning is edge-triggered on [WarningIssued]; **removing it is
/// level-triggered off [BreakEngine.phases]**, holding one invariant: the
/// warning notification is on screen if and only if the engine is in the
/// [Warning] phase.
///
/// Removal used to be edge-triggered too, and it leaked for the same reason
/// the pre-2026-07-14 overlay stranded windows — every path that ends a
/// warning without emitting one of the expected events left the banner in the
/// shell forever. Four did: a tray pause (emits nothing at all),
/// [BreakEngine.updateConfig] (drops the pending cycle silently), work hours
/// closing and a fullscreen video starting (emit only `EnginePausedBy*`,
/// which nothing listened for).
class NotificationCoordinator {
  NotificationCoordinator({
    required this._engine,
    required this._notifier,
    required this._sounds,
  });

  final BreakEngine _engine;
  final BreakNotifier _notifier;
  final SoundPlayer _sounds;
  StreamSubscription<EngineEvent>? _events;
  StreamSubscription<EnginePhase>? _phases;
  StreamSubscription<WarningAction>? _actions;

  /// Whether a warning has been raised and not yet taken back down. Guards the
  /// 1 Hz phase stream from queueing a redundant D-Bus round trip every second
  /// the engine spends outside [Warning].
  bool _warningShown = false;

  void start() {
    _events = _engine.events.listen((event) {
      switch (event) {
        case WarningIssued(:final kind, :final lead):
          _warningShown = true;
          unawaited(
            _notifier.showWarning(
              kind: kind,
              startsIn: lead,
              canSnooze: _engine.canSnooze,
              canSkip: _engine.canSkip,
            ),
          );
          unawaited(_sounds.play(AppSound.warning));
        case BreakStarted():
          unawaited(_sounds.play(AppSound.breakStarting));
        case BreakCompleted():
          unawaited(_sounds.play(AppSound.breakOver));
        default:
          break;
      }
    });
    _phases = _engine.phases.listen((phase) {
      if (phase is Warning || !_warningShown) return;
      _warningShown = false;
      unawaited(_notifier.dismissWarning());
    });
    _actions = _notifier.actions.listen((action) {
      switch (action) {
        case WarningAction.snooze:
          _engine.snooze();
        case WarningAction.startNow:
          _engine.startNow();
        case WarningAction.skip:
          _engine.skip();
      }
    });
  }

  Future<void> dispose() async {
    await _events?.cancel();
    await _phases?.cancel();
    await _actions?.cancel();
    await _notifier.dispose();
  }
}
