// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/engine/engine.dart';
import '../core/engine/events.dart';
import '../platform/interfaces/break_notifier.dart';
import '../platform/interfaces/sound_player.dart';

/// Turns engine events into the things the user actually sees and hears — the
/// pre-break warning notification and its sounds — and feeds the
/// notification's actions (Snooze / Start now / Skip) back into the engine.
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
  StreamSubscription<WarningAction>? _actions;

  void start() {
    _events = _engine.events.listen((event) {
      switch (event) {
        case WarningIssued(:final kind, :final lead):
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
          unawaited(_notifier.dismissWarning());
          unawaited(_sounds.play(AppSound.breakStarting));
        case BreakCompleted():
          unawaited(_notifier.dismissWarning());
          unawaited(_sounds.play(AppSound.breakOver));
        case BreakSnoozed() ||
            BreakSkipped() ||
            BreakDeferred() ||
            BreakCredited():
          unawaited(_notifier.dismissWarning());
        default:
          break;
      }
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
    await _actions?.cancel();
    await _notifier.dispose();
  }
}
