// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/platform/interfaces/break_notifier.dart';
import 'package:restifeye/platform/interfaces/sound_player.dart';
import 'package:restifeye/services/notification_coordinator.dart';

class _SpyNotifier implements BreakNotifier {
  int shown = 0;
  int dismissed = 0;

  @override
  Stream<WarningAction> get actions => const Stream.empty();

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
  Future<void> showInfo({required String title, required String body}) async {}

  @override
  Future<void> dispose() async {}
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
    ).start();
  }

  final clock = ManualClock();
  final notifier = _SpyNotifier();
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
}
