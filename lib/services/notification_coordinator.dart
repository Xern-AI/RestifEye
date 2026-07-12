import 'dart:async';

import '../core/engine/engine.dart';
import '../core/engine/events.dart';
import '../platform/interfaces/break_notifier.dart';

/// Connects engine events to the pre-break warning notification and feeds
/// notification actions (Snooze / Start now) back into the engine.
class NotificationCoordinator {
  NotificationCoordinator({required this._engine, required this._notifier});

  final BreakEngine _engine;
  final BreakNotifier _notifier;
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
            ),
          );
        case BreakStarted() ||
            BreakSnoozed() ||
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
      }
    });
  }

  Future<void> dispose() async {
    await _events?.cancel();
    await _actions?.cancel();
    await _notifier.dispose();
  }
}
