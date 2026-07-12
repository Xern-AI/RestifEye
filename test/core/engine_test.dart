import 'package:breaktime/core/clock.dart';
import 'package:breaktime/core/engine/engine.dart';
import 'package:breaktime/core/engine/events.dart';
import 'package:breaktime/core/engine/phase.dart';
import 'package:breaktime/core/models/break_config.dart';
import 'package:breaktime/core/models/break_kind.dart';
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
  });
}
