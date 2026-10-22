// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/platform/interfaces/app_log.dart';
import 'package:restifeye/platform/interfaces/break_notifier.dart';
import 'package:restifeye/platform/windows/windows_break_notifier.dart';

class _FakeToasts implements ToastBackend {
  _FakeToasts({this.accept = true});

  final bool accept;
  final calls = <String>[];
  final shown = <int, ToastSpec>{};
  void Function(String)? press;

  @override
  Future<bool> initialize(void Function(String argument) onActivated) async {
    press = onActivated;
    return accept;
  }

  @override
  Future<void> show(int id, ToastSpec spec) async {
    calls.add('show $id');
    shown[id] = spec;
  }

  @override
  Future<void> clearAll() async {
    calls.add('clear');
    shown.clear();
  }
}

void main() {
  late _FakeToasts toasts;
  late WindowsBreakNotifier notifier;

  setUp(() async {
    toasts = _FakeToasts();
    notifier = WindowsBreakNotifier(backend: toasts, log: const NoAppLog());
    await notifier.start();
  });

  tearDown(() => notifier.dispose());

  Future<void> warn({bool snooze = true, bool skip = true}) =>
      notifier.showWarning(
        kind: BreakKind.micro,
        startsIn: const Duration(seconds: 30),
        canSnooze: snooze,
        canSkip: skip,
      );

  test(
    'the warning says the same as on Linux and offers the allowed buttons',
    () async {
      await warn(skip: false);
      final spec = toasts.shown[1]!;
      expect(spec.title, 'Eye break in 30s');
      expect(spec.body, 'Time to rest your eyes for a moment.');
      expect(spec.actions.map((a) => a.$2), ['Start now', 'Snooze']);
      expect(spec.stayOnScreen, isFalse);
    },
  );

  test('a re-warn replaces the warning in place instead of stacking', () async {
    await warn();
    await warn();
    expect(toasts.calls, ['show 1', 'show 1']);
  });

  test(
    'dismissing a live warning clears; dismissing nothing does not',
    () async {
      await notifier.dismissWarning();
      expect(toasts.calls, isEmpty, reason: 'no clear storm every phase tick');

      await warn();
      await notifier.dismissWarning();
      await notifier.dismissWarning();
      expect(toasts.calls, ['show 1', 'clear']);
    },
  );

  test(
    'the on-hold notice stays on screen and comes down from the phase',
    () async {
      await notifier.showBreakHeld(kind: BreakKind.long);
      final spec = toasts.shown[2]!;
      expect(spec.stayOnScreen, isTrue);
      expect(spec.body, contains('movement break'));
      expect(spec.actions.single.$2, 'Return to break');

      await notifier.dismissBreakHeld();
      expect(toasts.calls, ['show 2', 'clear']);
    },
  );

  test(
    'button presses become engine actions; a body click does nothing',
    () async {
      final seen = <WarningAction>[];
      final sub = notifier.actions.listen(seen.add);
      for (final arg in ['start', 'snooze', 'skip', 'return', '', 'other']) {
        toasts.press!(arg);
      }
      await pumpEventQueue();
      expect(seen, [
        WarningAction.startNow,
        WarningAction.snooze,
        WarningAction.skip,
        WarningAction.returnToBreak,
      ]);
      await sub.cancel();
    },
  );

  test('a refused registration throws at start and then stays quiet', () async {
    final refused = _FakeToasts(accept: false);
    final quiet = WindowsBreakNotifier(backend: refused, log: const NoAppLog());
    await expectLater(quiet.start(), throwsStateError);
    await quiet.showInfo(title: 't', body: 'b');
    expect(refused.calls, isEmpty);
    await quiet.dispose();
  });
}
