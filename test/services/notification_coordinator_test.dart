// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/platform/interfaces/break_notifier.dart';
import 'package:restifeye/platform/interfaces/sound_player.dart';
import 'package:restifeye/services/notification_coordinator.dart';

class _SpyNotifier implements BreakNotifier {
  final _actions = StreamController<WarningAction>.broadcast(sync: true);
  int shown = 0;
  int dismissed = 0;
  int heldShown = 0;
  int heldDismissed = 0;

  @override
  Stream<WarningAction> get actions => _actions.stream;

  /// Fires a notification action, as the desktop would.
  void invoke(WarningAction action) => _actions.add(action);

  @override
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
    required bool canSkip,
  }) async => shown++;

  @override
  Future<void> dismissWarning() async => dismissed++;

  @override
  Future<void> showBreakHeld({required BreakKind kind}) async => heldShown++;

  @override
  Future<void> dismissBreakHeld() async => heldDismissed++;

  @override
  Future<void> showInfo({required String title, required String body}) async {}

  @override
  Future<void> dispose() async => _actions.close();
}

/// Drives a real engine into the warning phase, then hands the test whatever
/// interrupts it. Warning lead is deliberately long so the break never fires
/// on its own and every dismissal observed is the one under test.
class _Rig {
  _Rig({BreakConfig? config}) {
    engine = BreakEngine(
      clock: clock,
      config:
          config ??
          const BreakConfig(
            microInterval: Duration(seconds: 120),
            longInterval: Duration(hours: 1),
            warningLead: Duration(seconds: 115),
          ),
    );
    NotificationCoordinator(
      engine: engine,
      notifier: notifier,
      sounds: SilentSoundPlayer(),
      onReturnToBreak: () => returns++,
    ).start();
  }

  final clock = ManualClock();
  final notifier = _SpyNotifier();
  int returns = 0;
  late final BreakEngine engine;

  void run(Duration duration, [TickInput input = const TickInput()]) {
    for (var i = 0; i < duration.inSeconds; i++) {
      clock.advance(const Duration(seconds: 1));
      engine.tick(input);
    }
  }

  void toWarning() {
    run(const Duration(seconds: 12));
    expect(notifier.shown, 1, reason: 'warning should be up');
    expect(notifier.dismissed, 0, reason: 'nothing has ended it yet');
  }
}

void main() {
  group('warning notification is removed when the warning phase ends', () {
    test('the break starting takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      rig.engine.startNow();
      expect(rig.notifier.dismissed, 1);
    });

    test('a tray pause takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      rig.engine.setPausedByUser(true);
      expect(rig.notifier.dismissed, 1);
    });

    test('a fullscreen video takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      rig.run(const Duration(seconds: 1), const TickInput(presenting: true));
      expect(rig.notifier.dismissed, 1);
    });

    test('the work window closing takes it down', () {
      final rig = _Rig(
        config: const BreakConfig(
          microInterval: Duration(seconds: 120),
          longInterval: Duration(hours: 1),
          warningLead: Duration(seconds: 115),
          workStartMinutes: 9 * 60,
          workEndMinutes: 9 * 60 + 1,
        ),
      );
      rig.toWarning();
      rig.run(const Duration(seconds: 60));
      expect(rig.notifier.dismissed, 1);
    });

    test('a settings change takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      rig.engine.updateConfig(const BreakConfig());
      expect(rig.notifier.dismissed, 1);
    });

    test('a snooze takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      expect(rig.engine.snooze(), isTrue);
      expect(rig.notifier.dismissed, 1);
    });

    test('a skip takes it down', () {
      final rig = _Rig();
      rig.toWarning();
      expect(rig.engine.skip(), isTrue);
      expect(rig.notifier.dismissed, 1);
    });
  });

  test('a warning still up is never dismissed', () {
    final rig = _Rig();
    rig.toWarning();
    rig.run(const Duration(seconds: 30));
    expect(rig.notifier.shown, 1);
    expect(rig.notifier.dismissed, 0);
  });

  test('idle ticks after a dismissal do not re-dismiss', () {
    final rig = _Rig();
    rig.toWarning();
    rig.engine.setPausedByUser(true);
    rig.run(const Duration(seconds: 30));
    expect(
      rig.notifier.dismissed,
      1,
      reason: 'the phase stream must not queue a D-Bus call every second',
    );
  });

  group('break-on-hold notice', () {
    /// A break the user is looking at, with a long enough duration that the
    /// hold can outlive the notice threshold.
    _Rig atBreak() {
      final rig = _Rig(
        config: const BreakConfig(
          microInterval: Duration(seconds: 120),
          longInterval: Duration(hours: 1),
          warningLead: Duration(seconds: 115),
          microDuration: Duration(minutes: 2),
        ),
      );
      rig.toWarning();
      rig.engine.startNow();
      return rig;
    }

    test('nothing is raised for a brief switch away', () {
      final rig = atBreak();
      rig.run(const Duration(seconds: 8), const TickInput(breakFocused: false));
      expect(rig.notifier.heldShown, 0);
    });

    test('a sustained hold explains itself, exactly once', () {
      final rig = atBreak();
      rig.run(
        const Duration(seconds: 40),
        const TickInput(breakFocused: false),
      );
      expect(rig.notifier.heldShown, 1, reason: 'no banner per second');
      expect(rig.notifier.heldDismissed, 0);
    });

    test('coming back takes it down', () {
      final rig = atBreak();
      rig.run(
        const Duration(seconds: 20),
        const TickInput(breakFocused: false),
      );
      rig.run(const Duration(seconds: 1));
      expect(rig.notifier.heldDismissed, 1);
    });

    // Every way a break can end while held — the same defect class that once
    // stranded the warning banner forever.
    test('a break that ends while held takes it down', () {
      final rig = atBreak();
      rig.run(
        const Duration(seconds: 20),
        const TickInput(breakFocused: false),
      );
      rig.engine.setPausedByUser(true);
      expect(rig.notifier.heldDismissed, 1);
    });

    test('the return action is routed back to the window', () {
      final rig = atBreak();
      rig.notifier.invoke(WarningAction.returnToBreak);
      expect(rig.returns, 1);
    });
  });
}
