// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/engine/events.dart';
import 'package:restifeye/core/engine/phase.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test rig: drives the engine one second at a time, capturing events.
class Rig {
  Rig({BreakConfig? config, DateTime? startAt})
    : clock = ManualClock(startAt: startAt) {
    engine = BreakEngine(clock: clock, config: config ?? const BreakConfig());
    engine.events.listen(events.add);
  }

  final ManualClock clock;
  late final BreakEngine engine;
  final List<EngineEvent> events = [];

  /// Advances [duration] in 1 s steps, ticking with [input] each step.
  void run(Duration duration, [TickInput input = const TickInput()]) {
    var remaining = duration;
    const step = Duration(seconds: 1);
    while (remaining > Duration.zero) {
      clock.advance(step);
      engine.tick(input);
      remaining -= step;
    }
  }

  /// Simulates the user stopping all input: idle time climbs each second,
  /// exactly as a real idle monitor would report it.
  void runIdle(Duration duration) {
    var idle = Duration.zero;
    const step = Duration(seconds: 1);
    while (idle < duration) {
      idle += step;
      clock.advance(step);
      engine.tick(TickInput(idle: idle));
    }
  }

  List<T> eventsOf<T extends EngineEvent>() => events.whereType<T>().toList();
}

void main() {
  // Monday 09:00 — inside the default all-day work window.
  final monday9am = DateTime(2026, 1, 5, 9);

  group('scheduling', () {
    test('warns 30s before the micro interval, then starts the break', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19, seconds: 20));
      expect(rig.engine.phase, isA<Monitoring>());

      rig.run(const Duration(seconds: 15));
      expect(rig.engine.phase, isA<Warning>());
      expect(rig.eventsOf<WarningIssued>().single.kind, BreakKind.micro);

      rig.run(const Duration(seconds: 30));
      final phase = rig.engine.phase;
      expect(phase, isA<InBreak>());
      expect((phase as InBreak).kind, BreakKind.micro);
      expect(rig.eventsOf<BreakStarted>().single.strict, isFalse);
    });

    test('micro break completes after its duration and reschedules', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect(rig.engine.phase, isA<InBreak>());

      rig.run(const Duration(seconds: 25));
      expect(rig.eventsOf<BreakCompleted>().single.kind, BreakKind.micro);
      final phase = rig.engine.phase as Monitoring;
      expect(phase.nextBreakKind, BreakKind.micro);
      expect(phase.nextBreakIn, greaterThan(const Duration(minutes: 19)));
    });

    test('long break absorbs a micro break due within the merge window', () {
      // 20-minute micro + 21-minute long → both due together; long must win.
      final rig = Rig(
        config: const BreakConfig(longInterval: Duration(minutes: 21)),
      );
      rig.run(const Duration(minutes: 22));
      expect(rig.eventsOf<BreakStarted>().single.kind, BreakKind.long);
    });

    test('long break completion resets the micro timer too', () {
      final rig = Rig(
        config: const BreakConfig(
          longInterval: Duration(minutes: 21),
          longDuration: Duration(minutes: 1),
        ),
      );
      rig.run(const Duration(minutes: 23, seconds: 30));
      expect(rig.eventsOf<BreakCompleted>().single.kind, BreakKind.long);
      final phase = rig.engine.phase as Monitoring;
      // Micro is due a full interval after the long break ended, not before.
      expect(phase.nextBreakIn, greaterThan(const Duration(minutes: 19)));
    });

    test('wall-clock jumps do not affect interval math', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 10));
      rig.clock.jumpWallClock(const Duration(hours: 3)); // NTP / manual change
      rig.run(const Duration(seconds: 1));
      expect(rig.engine.phase, isA<Monitoring>());
      expect(rig.eventsOf<BreakStarted>(), isEmpty);
    });
  });

  group('monitoring exposes both timers', () {
    test('microIn and longIn count down independently', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 5));
      final phase = rig.engine.phase as Monitoring;
      expect(phase.microIn, const Duration(minutes: 15));
      expect(phase.longIn, const Duration(minutes: 45));
      expect(phase.nextBreakKind, BreakKind.micro);
      expect(phase.nextBreakIn, phase.microIn);
    });
  });

  group('snooze budget and strict mode', () {
    test('snoozing pushes the break back and depletes the budget', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect(rig.engine.phase, isA<InBreak>());

      expect(rig.engine.snooze(), isTrue);
      expect(rig.engine.phase, isA<Monitoring>());

      // Snoozed break comes due again after snoozeLength (2 min).
      rig.run(const Duration(minutes: 2, seconds: 1));
      expect(rig.engine.phase, isA<InBreak>());
      expect((rig.engine.phase as InBreak).snoozesLeft, 2);
    });

    test(
      'after the budget is exhausted the break is strict and snooze fails',
      () {
        final rig = Rig();
        rig.run(const Duration(minutes: 20, seconds: 5));
        expect(rig.engine.snooze(), isTrue);
        rig.run(const Duration(minutes: 2, seconds: 5));
        expect(rig.engine.snooze(), isTrue);
        rig.run(const Duration(minutes: 2, seconds: 5));
        expect(rig.engine.snooze(), isTrue);
        rig.run(const Duration(minutes: 2, seconds: 5));

        final phase = rig.engine.phase;
        expect(phase, isA<InBreak>());
        expect((phase as InBreak).strict, isTrue);
        expect(rig.engine.snooze(), isFalse);
        expect(rig.engine.phase, isA<InBreak>(), reason: 'strict break holds');
      },
    );

    test('completing a break restores the snooze budget for the next one', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 20, seconds: 5));
      rig.engine.snooze();
      rig.run(const Duration(minutes: 2, seconds: 5));
      rig.run(const Duration(seconds: 25)); // let it complete

      rig.run(const Duration(minutes: 20));
      expect((rig.engine.phase as InBreak).snoozesLeft, 3);
    });

    // Regression: the budget used to be one global counter shared by two
    // independently-scheduled cycles. Snoozing a long break pushes it past
    // `_microDue + mergeWindow`, so the *micro* break (already due) fires
    // next; completing that micro cycle refilled the shared counter, handing
    // the still-pending long break a fresh budget on top of what it had
    // already spent. Users reported snoozing a 3-budget long break 5 times.
    test('a micro cycle does not refill a pending long break\'s budget', () {
      // micro 20 / long 21 — the long lands inside the 2 min merge window,
      // so it is the kind that comes due first and absorbs the micro.
      final rig = Rig(
        config: const BreakConfig(
          microInterval: Duration(minutes: 20),
          longInterval: Duration(minutes: 21),
        ),
      );
      rig.run(const Duration(minutes: 21, seconds: 5));
      final started = rig.engine.phase as InBreak;
      expect(started.kind, BreakKind.long, reason: 'long absorbs the micro');

      // Snooze #1 of 3 on the long break.
      expect(rig.engine.snooze(), isTrue);

      // The long is now at +2 min, past micro's merge window, so the overdue
      // micro takes over and runs to completion.
      rig.run(const Duration(seconds: 5));
      expect((rig.engine.phase as InBreak).kind, BreakKind.micro);
      rig.run(const Duration(seconds: 25)); // micro completes (20 s)

      // Back to the long break. It must remember it already spent one snooze.
      rig.run(const Duration(minutes: 2, seconds: 5));
      final resumed = rig.engine.phase as InBreak;
      expect(resumed.kind, BreakKind.long);
      expect(
        resumed.snoozesLeft,
        2,
        reason: 'the long break spent one snooze before the micro interrupted',
      );

      // Only two snoozes may remain — the third attempt must fail.
      expect(rig.engine.snooze(), isTrue);
      rig.run(const Duration(minutes: 2, seconds: 5));
      expect(rig.engine.snooze(), isTrue);
      rig.run(const Duration(minutes: 2, seconds: 5));
      expect(
        rig.engine.snooze(),
        isFalse,
        reason: 'budget of 3 is spent; a 4th snooze must be refused',
      );
      expect((rig.engine.phase as InBreak).strict, isTrue);
    });

    test('each break kind carries its own snooze budget', () {
      final rig = Rig(
        config: const BreakConfig(
          microInterval: Duration(minutes: 20),
          longInterval: Duration(minutes: 60),
        ),
      );
      // Spend two snoozes on a micro break, then let it complete.
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect(rig.engine.snooze(), isTrue);
      rig.run(const Duration(minutes: 2, seconds: 5));
      expect(rig.engine.snooze(), isTrue);
      rig.run(const Duration(minutes: 2, seconds: 5));
      expect((rig.engine.phase as InBreak).snoozesLeft, 1);
      rig.run(const Duration(seconds: 25)); // completes

      // The long break is untouched by the micro's spending.
      rig.run(const Duration(minutes: 36));
      final long = rig.engine.phase as InBreak;
      expect(long.kind, BreakKind.long);
      expect(long.snoozesLeft, 3);
    });

    test('skip from the warning cancels the cycle and reschedules', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19, seconds: 40));
      expect(rig.engine.phase, isA<Warning>());

      expect(rig.engine.skip(), isTrue);
      expect(rig.eventsOf<BreakSkipped>().single.skipsLeft, 1);
      final phase = rig.engine.phase as Monitoring;
      expect(phase.nextBreakIn, greaterThan(const Duration(minutes: 19)));
      expect(rig.eventsOf<BreakStarted>(), isEmpty);
    });

    test('consecutive skips stop at the budget; completing a break resets '
        'it', () {
      // Long interval pushed out so only micro cycles run in this test.
      final rig = Rig(
        config: const BreakConfig(longInterval: Duration(hours: 3)),
      ); // default skipBudget = 2
      rig.run(const Duration(minutes: 19, seconds: 40));
      expect(rig.engine.skip(), isTrue);
      rig.run(const Duration(minutes: 19, seconds: 45));
      expect(rig.engine.skip(), isTrue);

      // Third consecutive skip must be refused and the break must fire.
      rig.run(const Duration(minutes: 19, seconds: 45));
      expect(rig.engine.canSkip, isFalse);
      expect(rig.engine.skip(), isFalse);
      rig.run(const Duration(seconds: 30));
      expect(rig.engine.phase, isA<InBreak>());

      // Completing the break restores the skip budget.
      rig.run(const Duration(seconds: 25));
      expect(rig.eventsOf<BreakCompleted>(), hasLength(1));
      expect(rig.engine.canSkip, isTrue);
    });

    test('skip does nothing outside warning/deferred and with a zero '
        'budget', () {
      final rig = Rig(config: const BreakConfig(skipBudget: 0));
      expect(rig.engine.skip(), isFalse); // monitoring
      rig.run(const Duration(minutes: 19, seconds: 40));
      expect(rig.engine.phase, isA<Warning>());
      expect(rig.engine.skip(), isFalse); // budget is zero
      rig.run(const Duration(seconds: 30));
      expect(rig.engine.phase, isA<InBreak>());
      expect(rig.engine.skip(), isFalse); // in-break is never skippable
      expect(rig.engine.phase, isA<InBreak>());
    });

    test('escape ends a strict break and is logged', () {
      final rig = Rig(config: const BreakConfig(snoozeBudget: 0));
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect((rig.engine.phase as InBreak).strict, isTrue);

      rig.engine.escape();
      expect(rig.eventsOf<BreakEscaped>().single.kind, BreakKind.micro);
      expect(rig.engine.phase, isA<Monitoring>());
    });
  });

  group('natural break credit', () {
    test('an away span >= long duration credits a long break', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 10));
      rig.run(const Duration(minutes: 6), const TickInput(locked: true));
      rig.run(const Duration(seconds: 1)); // return

      final credit = rig.eventsOf<BreakCredited>().single;
      expect(credit.kind, BreakKind.long);
      expect(credit.outcome, BreakOutcome.creditedLock);
      final phase = rig.engine.phase as Monitoring;
      expect(phase.nextBreakIn, greaterThan(const Duration(minutes: 19)));
    });

    test('a shorter idle span credits a micro break', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 15));
      // User stops typing; idle climbs past the 2-min threshold.
      rig.runIdle(const Duration(minutes: 3));
      rig.run(const Duration(seconds: 1)); // input resumes

      final credit = rig.eventsOf<BreakCredited>().single;
      expect(credit.kind, BreakKind.micro);
      expect(credit.outcome, BreakOutcome.creditedIdle);
    });

    test(
      'no break fires while the user is away; short absence re-warns on return',
      () {
        final rig = Rig();
        rig.run(const Duration(minutes: 19, seconds: 45));
        // Away for 90s across the due moment — too short to credit.
        rig.run(const Duration(seconds: 90), const TickInput(locked: true));
        expect(rig.eventsOf<BreakStarted>(), isEmpty);

        rig.run(const Duration(seconds: 2)); // return
        expect(rig.engine.phase, isA<Warning>());
        rig.run(const Duration(seconds: 16));
        expect(rig.engine.phase, isA<InBreak>());
      },
    );
  });

  group('media pause', () {
    const playing = TickInput(presenting: true, presentingApp: 'mpv');

    test('a fullscreen video pauses scheduling outright', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 5));
      rig.run(const Duration(minutes: 1), playing);

      final phase = rig.engine.phase;
      expect(phase, isA<Paused>());
      expect((phase as Paused).reason, PauseReason.media);
      expect(phase.byApp, 'mpv');
      expect(phase.byUser, isFalse, reason: 'must not light up the UI toggle');
      expect(rig.eventsOf<EnginePausedByMedia>().single.byApp, 'mpv');
    });

    test('no break fires during a two-hour film', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 5));
      rig.run(const Duration(hours: 2), playing);

      expect(rig.eventsOf<BreakStarted>(), isEmpty);
      expect(rig.engine.phase, isA<Paused>());
    });

    // The whole point of the deferral cap is that a break can only be pushed
    // so far. Media pause deliberately has no cap — a cap would guarantee the
    // interruption the feature exists to prevent.
    test('the media pause is not subject to the deferral cap', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19), playing);
      rig.run(const Duration(minutes: 30), playing);
      expect(rig.eventsOf<BreakStarted>(), isEmpty);
      expect(rig.eventsOf<BreakDeferred>(), isEmpty);
    });

    test('timers are not reset when the video ends', () {
      final rig = Rig();
      // 15 min of work, then a 40 min film. 5 min of the interval remain.
      rig.run(const Duration(minutes: 15));
      rig.run(const Duration(minutes: 40), playing);
      expect(rig.engine.phase, isA<Paused>());

      // Resuming must not restart the 20 min interval: the break is already
      // overdue, so it arrives after the short re-warn lead, not 20 min later.
      rig.run(const Duration(seconds: 1));
      expect(rig.engine.phase, isA<Warning>());
      rig.run(const Duration(seconds: 20));
      expect(
        rig.engine.phase,
        isA<InBreak>(),
        reason: 'an overdue break resumes promptly, not on a fresh interval',
      );
    });

    // Watching counts as screen time: the interval keeps running down during
    // the film, it just never fires. So a short video does not push the next
    // break back, and a long one leaves it overdue (covered above). What must
    // never happen is the interval *restarting*, which would let a film buy
    // the user a fresh 20 minutes.
    test('a film consumes interval time rather than resetting it', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 5));
      rig.run(const Duration(minutes: 10), playing);
      rig.run(const Duration(seconds: 1));

      final phase = rig.engine.phase;
      expect(phase, isA<Monitoring>());
      // 15 min of the 20 min interval have elapsed; ~5 remain.
      expect((phase as Monitoring).microIn.inSeconds, closeTo(299, 3));
    });

    test('film time is never credited as a natural break', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 5));
      // Watching a film without touching the keyboard looks exactly like
      // being idle. It is not rest, and must not earn a credited break.
      var idle = Duration.zero;
      for (var i = 0; i < 60 * 30; i++) {
        idle += const Duration(seconds: 1);
        rig.clock.advance(const Duration(seconds: 1));
        rig.engine.tick(
          TickInput(idle: idle, presenting: true, presentingApp: 'mpv'),
        );
      }
      rig.run(const Duration(seconds: 1));
      expect(rig.eventsOf<BreakCredited>(), isEmpty);
    });

    test('a break already on screen is left to finish', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect(rig.engine.phase, isA<InBreak>());

      // Going fullscreen mid-break must not abandon it — that would log a
      // BreakEscaped the user never earned.
      rig.run(const Duration(seconds: 5), playing);
      expect(rig.engine.phase, isA<InBreak>());
      expect(rig.eventsOf<BreakEscaped>(), isEmpty);
    });

    test('a user pause outranks a media pause', () {
      final rig = Rig();
      rig.engine.setPausedByUser(true);
      rig.run(const Duration(minutes: 1), playing);
      expect((rig.engine.phase as Paused).reason, PauseReason.user);
    });
  });

  group('busy deferral', () {
    test('a due break defers while the mic is in use', () {
      final rig = Rig();
      rig.run(
        const Duration(minutes: 20, seconds: 5),
        const TickInput(busy: true),
      );
      expect(rig.engine.phase, isA<Deferred>());
      expect(rig.eventsOf<BreakStarted>(), isEmpty);
    });

    test('deferral ends with a short re-warning once no longer busy', () {
      final rig = Rig();
      rig.run(
        const Duration(minutes: 20, seconds: 5),
        const TickInput(busy: true),
      );
      rig.run(const Duration(minutes: 5), const TickInput(busy: true));
      rig.run(const Duration(seconds: 1)); // call over → recheck passes
      expect(rig.engine.phase, isA<Warning>());
      rig.run(const Duration(seconds: 16));
      expect(rig.engine.phase, isA<InBreak>());
    });

    test('the deferral cap forces the break even if still busy', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 40), const TickInput(busy: true));
      expect(
        rig.eventsOf<BreakStarted>(),
        isNotEmpty,
        reason: 'cap (15 min) must have forced the break',
      );
    });
  });

  group('work hours', () {
    test('engine pauses outside the work window and resumes inside it', () {
      // Work 09:00–17:00; start at 16:55.
      final rig = Rig(
        config: const BreakConfig(
          workStartMinutes: 9 * 60,
          workEndMinutes: 17 * 60,
        ),
        startAt: DateTime(2026, 1, 5, 16, 55),
      );
      rig.run(const Duration(minutes: 6));
      expect(rig.engine.phase, isA<Paused>());
      expect(rig.eventsOf<EnginePausedByWorkHours>(), hasLength(1));

      // Next morning 09:00 (advance 16h05m).
      rig.run(const Duration(hours: 16, minutes: 5));
      expect(rig.engine.phase, isA<Monitoring>());
      expect(rig.eventsOf<EngineResumed>(), hasLength(1));
    });

    test('non-work days are fully paused', () {
      final rig = Rig(
        config: const BreakConfig(workDays: {1, 2, 3, 4, 5}),
        startAt: DateTime(2026, 1, 10, 12), // Saturday
      );
      rig.run(const Duration(minutes: 30));
      expect(rig.engine.phase, isA<Paused>());
      expect(rig.eventsOf<BreakStarted>(), isEmpty);
    });
  });

  group('snapshot & restore', () {
    test('timers survive a restart via snapshot', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 15));
      final snap = rig.engine.snapshot();

      // "Restart" 1 minute later on a fresh monotonic clock.
      final clock2 = ManualClock(
        startAt: rig.clock.now().add(const Duration(minutes: 1)),
      );
      final engine2 = BreakEngine(
        clock: clock2,
        config: const BreakConfig(),
        restoreFrom: snap,
      );
      final events2 = <EngineEvent>[];
      engine2.events.listen(events2.add);

      // 20 - 15 - 1 = 4 minutes remain; warning fires 30 s before.
      for (var i = 0; i < 4 * 60 - 20; i++) {
        clock2.advance(const Duration(seconds: 1));
        engine2.tick(const TickInput());
      }
      expect(engine2.phase, isA<Warning>());
    });

    test('a long gap before restore resets timers fresh', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19));
      final snap = rig.engine.snapshot();

      final clock2 = ManualClock(
        startAt: rig.clock.now().add(const Duration(hours: 2)),
      );
      final engine2 = BreakEngine(
        clock: clock2,
        config: const BreakConfig(),
        restoreFrom: snap,
      );
      clock2.advance(const Duration(seconds: 1));
      engine2.tick(const TickInput());
      final phase = engine2.phase as Monitoring;
      expect(phase.nextBreakIn, greaterThan(const Duration(minutes: 18)));
    });

    // Regression: snooze/skip budgets are per-cycle and not persisted, so
    // they must be seeded on the restore path too. Leaving _snoozesLeft at 0
    // made the first break after *every* login strict — no Snooze action on
    // its notification, and a forced full-screen takeover.
    test('a restored engine starts with a full snooze budget', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 15));
      final snap = rig.engine.snapshot();

      final clock2 = ManualClock(
        startAt: rig.clock.now().add(const Duration(minutes: 1)),
      );
      final engine2 = BreakEngine(
        clock: clock2,
        config: const BreakConfig(),
        restoreFrom: snap,
      );

      expect(engine2.canSnooze, isTrue);
      expect(engine2.canSkip, isTrue);
    });

    test('the first break after a restore is not strict', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 15));
      final snap = rig.engine.snapshot();

      final clock2 = ManualClock(
        startAt: rig.clock.now().add(const Duration(minutes: 1)),
      );
      final engine2 = BreakEngine(
        clock: clock2,
        config: const BreakConfig(),
        restoreFrom: snap,
      );
      // 20 - 15 - 1 = 4 minutes to the break.
      for (var i = 0; i < 4 * 60 + 1; i++) {
        clock2.advance(const Duration(seconds: 1));
        engine2.tick(const TickInput());
      }

      final phase = engine2.phase as InBreak;
      expect(phase.strict, isFalse);
      expect(phase.snoozesLeft, const BreakConfig().snoozeBudget);
    });
  });

  group('away during a break', () {
    // THE regression test. A movement break is *meant* to get the user away
    // from the keyboard. Away-tracking used to run during breaks, so idling
    // past idleFireThreshold credited an away span from inside the break:
    // _finishCycle ran, the inBreak case never did, BreakCompleted never
    // fired — and nothing ever told the window to leave full-screen. The
    // user was left in an undecorated, always-on-top window that would not
    // close.
    test('a long break the user sits out still completes exactly once', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 49, seconds: 40));
      expect(rig.engine.phase, isA<Warning>());
      // Micro breaks legitimately fired during the run-up; only the long
      // break is under test.
      rig.events.clear();
      rig.engine.startNow();
      expect(rig.engine.phase, isA<InBreak>());

      // 5-minute long break, spent away from the keyboard as intended.
      rig.runIdle(const Duration(minutes: 5, seconds: 30));

      expect(rig.eventsOf<BreakCompleted>(), hasLength(1));
      expect(
        rig.eventsOf<BreakCredited>(),
        isEmpty,
        reason: 'the break IS the rest — it must not also be credited',
      );
      expect(rig.engine.phase, isA<Monitoring>());
    });

    test('going idle mid-break does not end the cycle early', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 49, seconds: 40));
      rig.events.clear();
      rig.engine.startNow();

      // Idle well past idleFireThreshold (2 min) but short of the break end.
      rig.runIdle(const Duration(minutes: 3));

      expect(
        rig.engine.phase,
        isA<InBreak>(),
        reason: 'the break must still be running',
      );
      expect(rig.eventsOf<BreakCompleted>(), isEmpty);
      expect(rig.eventsOf<BreakCredited>(), isEmpty);
    });

    // The idle clock keeps counting through a break the user sat out, so an
    // unclamped backdate measured the break itself as a fresh away span and
    // handed out a second break's credit the moment they typed again.
    test('a break the user sat out is not also credited as an away span', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 49, seconds: 40));
      rig.events.clear();
      rig.engine.startNow();

      // Sit out the whole 5-minute break, then return to the keyboard.
      rig.runIdle(const Duration(minutes: 5, seconds: 20));
      rig.run(const Duration(seconds: 5)); // idle back to zero

      expect(rig.eventsOf<BreakCompleted>(), hasLength(1));
      expect(
        rig.eventsOf<BreakCredited>(),
        isEmpty,
        reason:
            'the break was already counted — crediting it again would '
            'push the next long break out by a whole interval',
      );
    });

    test('a timed pause resumes on its own', () {
      final rig = Rig(startAt: monday9am);
      rig.engine.setPausedByUser(
        true,
        until: monday9am.add(const Duration(minutes: 30)),
      );
      expect(rig.engine.phase, isA<Paused>());

      rig.run(const Duration(minutes: 29));
      expect(
        rig.engine.phase,
        isA<Paused>(),
        reason: 'still inside the pause window',
      );

      rig.run(const Duration(minutes: 2));
      expect(
        rig.engine.phase,
        isA<Monitoring>(),
        reason: 'the whole point of a timed pause is that it ends by itself',
      );
      expect(rig.eventsOf<EngineResumed>(), hasLength(1));
    });

    test('an open-ended pause never resumes by itself', () {
      final rig = Rig(startAt: monday9am);
      rig.engine.setPausedByUser(true);
      rig.run(const Duration(hours: 8));
      expect(rig.engine.phase, isA<Paused>());
      expect((rig.engine.phase as Paused).until, isNull);
    });

    test('the pause deadline is exposed for the countdown', () {
      final rig = Rig(startAt: monday9am);
      final until = monday9am.add(const Duration(hours: 3));
      rig.engine.setPausedByUser(true, until: until);
      expect((rig.engine.phase as Paused).until, until);
    });

    test('pausing during a break ends it so the window can be released', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19, seconds: 40));
      rig.engine.startNow();
      expect(rig.engine.phase, isA<InBreak>());

      rig.engine.setPausedByUser(true);

      expect(rig.eventsOf<BreakEscaped>(), hasLength(1));
      expect(rig.engine.phase, isA<Paused>());
    });
  });

  group('user controls', () {
    test('startNow begins the break from the warning immediately', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19, seconds: 40));
      expect(rig.engine.phase, isA<Warning>());
      rig.engine.startNow();
      expect(rig.engine.phase, isA<InBreak>());
    });

    test('pause by user stops all scheduling until resumed', () {
      final rig = Rig();
      rig.engine.setPausedByUser(true);
      rig.run(const Duration(hours: 1));
      expect(rig.eventsOf<BreakStarted>(), isEmpty);

      rig.engine.setPausedByUser(false);
      rig.run(const Duration(minutes: 20, seconds: 5));
      expect(rig.engine.phase, isA<InBreak>());
    });

    test('config update restarts timers predictably', () {
      final rig = Rig();
      rig.run(const Duration(minutes: 19));
      rig.engine.updateConfig(
        rig.engine.config.copyWith(microInterval: const Duration(minutes: 30)),
      );
      rig.run(const Duration(minutes: 2));
      expect(
        rig.eventsOf<BreakStarted>(),
        isEmpty,
        reason: 'new 30-min interval restarted from the config change',
      );
      final phase = rig.engine.phase as Monitoring;
      expect(phase.nextBreakIn, lessThan(const Duration(minutes: 29)));
    });
  });

  group('regression guards', () {
    test('default config starts inside work hours on a weekday', () {
      expect(const BreakConfig().isWithinWorkHours(monday9am), isTrue);
    });

    test('overnight work window spans midnight correctly', () {
      const config = BreakConfig(
        workStartMinutes: 22 * 60,
        workEndMinutes: 6 * 60,
      );
      expect(config.isWithinWorkHours(DateTime(2026, 1, 5, 23)), isTrue);
      expect(config.isWithinWorkHours(DateTime(2026, 1, 5, 5)), isTrue);
      expect(config.isWithinWorkHours(DateTime(2026, 1, 5, 12)), isFalse);
    });

    test('equal start and end means all day, not a dead window', () {
      const midnight = BreakConfig(workStartMinutes: 0, workEndMinutes: 0);
      expect(midnight.isAllDay, isTrue);
      expect(midnight.isWithinWorkHours(monday9am), isTrue);
      expect(midnight.isWithinWorkHours(DateTime(2026, 1, 5, 3)), isTrue);

      const nineToNine = BreakConfig(
        workStartMinutes: 9 * 60,
        workEndMinutes: 9 * 60,
      );
      expect(nineToNine.isAllDay, isTrue);
      expect(nineToNine.isWithinWorkHours(DateTime(2026, 1, 5, 3)), isTrue);
    });

    test('default config reports an all-day window', () {
      expect(const BreakConfig().isAllDay, isTrue);
      expect(
        const BreakConfig(
          workStartMinutes: 9 * 60,
          workEndMinutes: 17 * 60,
        ).isAllDay,
        isFalse,
      );
    });

    test('resetting to the defaults restores the all-day window', () {
      const narrowed = BreakConfig(
        workStartMinutes: 9 * 60,
        workEndMinutes: 17 * 60,
      );
      final reset = narrowed.copyWith(
        workStartMinutes: BreakConfig.defaultWorkStartMinutes,
        workEndMinutes: BreakConfig.defaultWorkEndMinutes,
      );
      expect(reset.isAllDay, isTrue);
      expect(reset.isWithinWorkHours(DateTime(2026, 1, 5, 3)), isTrue);
    });
  });
}
