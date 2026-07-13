import 'package:breaktime/core/clock.dart';
import 'package:breaktime/core/engine/events.dart';
import 'package:breaktime/core/models/activity.dart';
import 'package:breaktime/core/models/break_kind.dart';
import 'package:breaktime/data/activity_repository.dart';
import 'package:breaktime/data/break_log_repository.dart';
import 'package:breaktime/data/database.dart';
import 'package:breaktime/data/rollup_repository.dart';
import 'package:breaktime/services/rollup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository activity;
  late BreakLogRepository breakLog;
  late RollupRepository rollups;
  late ManualClock clock;
  late RollupService service;

  // "Today" for the service = 2026-01-07; data lives on the 5th and 6th.
  final today = DateTime(2026, 1, 7, 10);

  setUp(() {
    db = AppDatabase.inMemory();
    activity = ActivityRepository(db);
    breakLog = BreakLogRepository(db);
    rollups = RollupRepository(db);
    clock = ManualClock(startAt: today);
    service = RollupService(
      activity: activity,
      breakLog: breakLog,
      rollups: rollups,
      clock: clock,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  Future<void> seedDay(DateTime day, {required int activeMinutes}) async {
    await activity.insertSlice(
      ActivitySlice(
        start: day.add(const Duration(hours: 9)),
        end: day.add(Duration(hours: 9, minutes: activeMinutes)),
        kind: SliceKind.active,
      ),
    );
    await breakLog.record(
      BreakCompleted(day.add(const Duration(hours: 10)), BreakKind.micro),
    );
  }

  test('rolls up all finished days and leaves today alone', () async {
    await seedDay(DateTime(2026, 1, 5), activeMinutes: 120);
    await seedDay(DateTime(2026, 1, 6), activeMinutes: 90);
    await seedDay(DateTime(2026, 1, 7), activeMinutes: 30); // today

    await service.run();

    final stored = await rollups
        .watchRange(DateTime(2026, 1, 1), DateTime(2026, 1, 8))
        .first;
    expect(stored, hasLength(2));
    expect(stored[0].day, DateTime(2026, 1, 5));
    expect(stored[0].screen, const Duration(hours: 2));
    expect(stored[0].completed, 1);
    expect(stored[1].screen, const Duration(minutes: 90));
  });

  test('is idempotent and fills gaps with empty days', () async {
    await seedDay(DateTime(2026, 1, 3), activeMinutes: 60);
    // Nothing on the 4th–6th.
    await service.run();
    await service.run(); // second run must not duplicate or fail

    final stored = await rollups
        .watchRange(DateTime(2026, 1, 1), DateTime(2026, 1, 8))
        .first;
    expect(stored, hasLength(4)); // 3rd, 4th, 5th, 6th
    expect(stored[1].screen, Duration.zero);
  });

  test('prunes raw slices older than the retention window', () async {
    await seedDay(DateTime(2025, 12, 20), activeMinutes: 60);
    await seedDay(DateTime(2026, 1, 6), activeMinutes: 60);

    await service.run();

    final remaining = await db.select(db.activitySlices).get();
    expect(remaining, hasLength(1));
    expect(remaining.single.startAt.day, 6);
  });
}
