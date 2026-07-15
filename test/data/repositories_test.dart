import 'package:restifeye/core/engine/events.dart';
import 'package:restifeye/core/models/activity.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/data/activity_repository.dart';
import 'package:restifeye/data/break_log_repository.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  group('SettingsRepository', () {
    test('returns defaults when no config was saved', () async {
      final repo = SettingsRepository(db);
      final config = await repo.loadConfig();
      expect(config.microInterval, const Duration(minutes: 20));
      expect(config.snoozeBudget, 3);
    });

    test('round-trips a customized config', () async {
      final repo = SettingsRepository(db);
      await repo.saveConfig(
        const BreakConfig(
          microInterval: Duration(minutes: 25),
          snoozeBudget: 1,
          workDays: {1, 3, 5},
          strictMode: false,
        ),
      );
      final loaded = await repo.loadConfig();
      expect(loaded.microInterval, const Duration(minutes: 25));
      expect(loaded.snoozeBudget, 1);
      expect(loaded.workDays, {1, 3, 5});
      expect(loaded.strictMode, isFalse);
    });

    test('falls back to defaults on a corrupt config row', () async {
      final repo = SettingsRepository(db);
      await db
          .into(db.settingRows)
          .insert(
            SettingRowsCompanion.insert(key: 'break_config', value: '{oops'),
          );
      final config = await repo.loadConfig();
      expect(config.microInterval, const Duration(minutes: 20));
    });

    test('flags default and persist', () async {
      final repo = SettingsRepository(db);
      expect(
        await repo.getFlag(
          SettingsRepository.flagOnboardingDone,
          fallback: false,
        ),
        isFalse,
      );
      await repo.setFlag(SettingsRepository.flagOnboardingDone, true);
      expect(
        await repo.getFlag(
          SettingsRepository.flagOnboardingDone,
          fallback: false,
        ),
        isTrue,
      );
    });
  });

  group('ActivityRepository', () {
    test('stats aggregate only the requested day and active slices', () async {
      final repo = ActivityRepository(db);
      final day = DateTime(2026, 7, 10);

      Future<void> add(
        int startHour,
        int minutes,
        SliceKind kind, {
        int dayOffset = 0,
      }) {
        final start = day.add(Duration(days: dayOffset, hours: startHour));
        return repo.insertSlice(
          ActivitySlice(
            start: start,
            end: start.add(Duration(minutes: minutes)),
            kind: kind,
          ),
        );
      }

      await add(9, 50, SliceKind.active);
      await add(10, 5, SliceKind.idle);
      await add(11, 90, SliceKind.active);
      await add(13, 30, SliceKind.locked);
      await add(9, 480, SliceKind.active, dayOffset: 1); // other day

      final stats = await repo.watchSliceStats(day).first;
      expect(stats.screenTime, const Duration(minutes: 140));
      expect(stats.longestStretch, const Duration(minutes: 90));
    });

    test('splits a midnight-spanning slice between both days', () async {
      final repo = ActivityRepository(db);
      final day = DateTime(2026, 7, 14);
      final nextDay = DateTime(2026, 7, 15);

      await repo.insertSlice(
        ActivitySlice(
          start: DateTime(2026, 7, 14, 22),
          end: DateTime(2026, 7, 14, 23),
          kind: SliceKind.active,
        ),
      );
      // Locked through midnight: an hour and a half split 1h / 30m.
      await repo.insertSlice(
        ActivitySlice(
          start: DateTime(2026, 7, 14, 23),
          end: DateTime(2026, 7, 15, 0, 30),
          kind: SliceKind.locked,
        ),
      );
      await repo.insertSlice(
        ActivitySlice(
          start: DateTime(2026, 7, 15, 0, 30),
          end: DateTime(2026, 7, 15, 1),
          kind: SliceKind.active,
        ),
      );

      final first = await repo.watchSliceStats(day).first;
      expect(first.screenTime, const Duration(hours: 1));
      expect(first.awayTime, const Duration(hours: 1));

      final second = await repo.watchSliceStats(nextDay).first;
      expect(second.awayTime, const Duration(minutes: 30));
      expect(second.screenTime, const Duration(minutes: 30));
      expect(second.firstActivity, DateTime(2026, 7, 15, 0, 30));
    });

    test(
      'clamps the workday span of an active slice crossing midnight',
      () async {
        final repo = ActivityRepository(db);
        await repo.insertSlice(
          ActivitySlice(
            start: DateTime(2026, 7, 16, 23, 30),
            end: DateTime(2026, 7, 17, 0, 15),
            kind: SliceKind.active,
          ),
        );

        final before = await repo.watchSliceStats(DateTime(2026, 7, 16)).first;
        expect(before.screenTime, const Duration(minutes: 30));
        expect(before.lastActivity, DateTime(2026, 7, 17));

        final after = await repo.watchSliceStats(DateTime(2026, 7, 17)).first;
        expect(after.screenTime, const Duration(minutes: 15));
        expect(after.firstActivity, DateTime(2026, 7, 17));
      },
    );

    test('pruneBefore removes only fully old slices', () async {
      final repo = ActivityRepository(db);
      final cutoff = DateTime(2026, 7, 10);
      await repo.insertSlice(
        ActivitySlice(
          start: cutoff.subtract(const Duration(hours: 2)),
          end: cutoff.subtract(const Duration(hours: 1)),
          kind: SliceKind.active,
        ),
      );
      await repo.insertSlice(
        ActivitySlice(
          start: cutoff.add(const Duration(hours: 1)),
          end: cutoff.add(const Duration(hours: 2)),
          kind: SliceKind.active,
        ),
      );

      expect(await repo.pruneBefore(cutoff), 1);
      final remaining = await db.select(db.activitySlices).get();
      expect(remaining, hasLength(1));
    });
  });

  group('BreakLogRepository', () {
    test('maps engine events to rows and counts a day correctly', () async {
      final repo = BreakLogRepository(db);
      final at = DateTime(2026, 7, 10, 10);

      await repo.record(
        WarningIssued(at, BreakKind.micro, const Duration(seconds: 30)),
      );
      await repo.record(BreakStarted(at, BreakKind.micro, strict: false));
      await repo.record(BreakSnoozed(at, BreakKind.micro, snoozesLeft: 2));
      await repo.record(BreakCompleted(at, BreakKind.micro));
      await repo.record(
        BreakCredited(
          at,
          BreakKind.long,
          BreakOutcome.creditedLock,
          const Duration(minutes: 6),
        ),
      );
      await repo.record(BreakEscaped(at, BreakKind.long));
      // Non-break events must be ignored, not crash:
      await repo.record(EnginePausedByWorkHours(at));
      await repo.record(EngineResumed(at));
      // Different day must not count:
      await repo.record(
        BreakCompleted(at.add(const Duration(days: 1)), BreakKind.micro),
      );

      final counts = await repo.watchDayCounts(at).first;
      expect(counts.completed, 1);
      expect(counts.credited, 1);
      expect(counts.escaped, 1);
      expect(counts.snoozes, 1);
    });
  });
}
