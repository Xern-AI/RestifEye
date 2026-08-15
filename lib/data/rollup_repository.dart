// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:drift/drift.dart';

import 'database.dart';

/// One day of aggregated stats, as stored in daily_rollups.
typedef DayRollup = ({
  DateTime day,
  Duration screen,
  Duration idle,
  Duration watch,
  Duration away,
  Duration longestStretch,
  int focusRuns,
  // Minutes since local midnight; null on days rolled up before schema v2.
  int? firstActivityMinute,
  int? lastActivityMinute,
  // Hands-on seconds per hour; empty on days rolled up before schema v3.
  List<int> activeByHour,
  int completed,
  int credited,
  int escaped,
  int snoozes,
});

/// Time at the machine, hands on or not.
Duration atComputerOf(DayRollup r) => r.screen + r.idle + r.watch;

/// Serialises the hourly profile. Empty means "not recorded", which is why
/// it is stored as null rather than as 24 zeroes — a day before the column
/// existed did not have a quiet 24 hours, we simply do not know.
String? _encodeHours(List<int> seconds) =>
    seconds.isEmpty ? null : seconds.join(',');

List<int> _decodeHours(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final parts = raw.split(',');
  if (parts.length != 24) return const [];
  final hours = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    // One unparseable field makes the whole profile untrustworthy; reporting
    // nothing beats reporting a day with a hole in it.
    if (value == null || value < 0) return const [];
    hours.add(value);
  }
  return hours;
}

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
          watchSeconds: Value(rollup.watch.inSeconds),
          focusRuns: Value(rollup.focusRuns),
          activeByHour: Value(_encodeHours(rollup.activeByHour)),
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
            watch: Duration(seconds: row.watchSeconds),
            away: Duration(seconds: row.awaySeconds),
            longestStretch: Duration(seconds: row.longestStretchSeconds),
            focusRuns: row.focusRuns,
            firstActivityMinute: row.firstActivityMinute,
            lastActivityMinute: row.lastActivityMinute,
            activeByHour: _decodeHours(row.activeByHour),
            completed: row.breaksCompleted,
            credited: row.breaksCredited,
            escaped: row.breaksEscaped,
            snoozes: row.snoozes,
          ),
      ],
    );
  }
}
