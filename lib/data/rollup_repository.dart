import 'package:drift/drift.dart';

import 'database.dart';

/// One day of aggregated stats, as stored in daily_rollups.
typedef DayRollup = ({
  DateTime day,
  Duration screen,
  Duration idle,
  Duration away,
  Duration longestStretch,
  // Minutes since local midnight; null on days rolled up before schema v2.
  int? firstActivityMinute,
  int? lastActivityMinute,
  int completed,
  int credited,
  int escaped,
  int snoozes,
});

/// Time at the machine, hands on or not.
Duration atComputerOf(DayRollup r) => r.screen + r.idle;

class RollupRepository {
  RollupRepository(this._db);

  final AppDatabase _db;

  Future<void> upsert(DayRollup rollup) => _db
      .into(_db.dailyRollups)
      .insertOnConflictUpdate(
        DailyRollupsCompanion.insert(
          day: rollup.day,
          screenSeconds: rollup.screen.inSeconds,
          longestStretchSeconds: rollup.longestStretch.inSeconds,
          breaksCompleted: rollup.completed,
          breaksCredited: rollup.credited,
          breaksEscaped: rollup.escaped,
          snoozes: rollup.snoozes,
          idleSeconds: Value(rollup.idle.inSeconds),
          awaySeconds: Value(rollup.away.inSeconds),
          firstActivityMinute: Value(rollup.firstActivityMinute),
          lastActivityMinute: Value(rollup.lastActivityMinute),
        ),
      );

  /// Most recent rolled-up day, or null when none exist yet.
  Future<DateTime?> latestDay() async {
    final query = _db.select(_db.dailyRollups)
      ..orderBy([(t) => OrderingTerm.desc(t.day)])
      ..limit(1);
    return (await query.getSingleOrNull())?.day;
  }

  /// Rollups within [from, to), oldest first.
  Stream<List<DayRollup>> watchRange(DateTime from, DateTime to) {
    final query = _db.select(_db.dailyRollups)
      ..where((t) => t.day.isBiggerOrEqualValue(from))
      ..where((t) => t.day.isSmallerThanValue(to))
      ..orderBy([(t) => OrderingTerm.asc(t.day)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            day: row.day,
            screen: Duration(seconds: row.screenSeconds),
            idle: Duration(seconds: row.idleSeconds),
            away: Duration(seconds: row.awaySeconds),
            longestStretch: Duration(seconds: row.longestStretchSeconds),
            firstActivityMinute: row.firstActivityMinute,
            lastActivityMinute: row.lastActivityMinute,
            completed: row.breaksCompleted,
            credited: row.breaksCredited,
            escaped: row.breaksEscaped,
            snoozes: row.snoozes,
          ),
      ],
    );
  }
}
