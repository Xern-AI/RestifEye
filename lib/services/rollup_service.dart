// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/clock.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/rollup_repository.dart';

/// Folds finished days into daily_rollups and prunes old raw slices.
/// Runs at startup and every few hours; idempotent.
class RollupService {
  RollupService({
    required this._activity,
    required this._breakLog,
    required this._rollups,
    required this._clock,
  });

  static const _keepRawSlices = Duration(days: 7);
  static const _runEvery = Duration(hours: 6);

  final ActivityRepository _activity;
  final BreakLogRepository _breakLog;
  final RollupRepository _rollups;
  final Clock _clock;
  Timer? _timer;

  void start() {
    unawaited(run());
    _timer = Timer.periodic(_runEvery, (_) => unawaited(run()));
  }

  Future<void> run() async {
    final now = _clock.now();
    final today = DateTime(now.year, now.month, now.day);

    var day = await _firstUnrolledDay(today);
    if (day == null) return;

    while (day!.isBefore(today)) {
      final stats = await _activity.sliceStatsFor(day);
      final counts = await _breakLog.countsFor(day);
      await _rollups.upsert((
        day: day,
        screen: stats.screenTime,
        idle: stats.idleTime,
        watch: stats.watchTime,
        away: stats.awayTime,
        longestStretch: stats.longestStretch,
        focusRuns: stats.focusRuns,
        firstActivityMinute: _minuteOfDay(stats.firstActivity),
        lastActivityMinute: _minuteOfDay(stats.lastActivity),
        activeByHour: [for (final hour in stats.hours) hour.active],
        completed: counts.completed,
        credited: counts.credited,
        escaped: counts.escaped,
        snoozes: counts.snoozes,
      ));
      day = _nextDay(day);
    }

    await _activity.pruneBefore(today.subtract(_keepRawSlices));
  }

  Future<DateTime?> _firstUnrolledDay(DateTime today) async {
    final latest = await _rollups.latestDay();
    if (latest != null) return _nextDay(latest);
    final earliest = await _activity.earliestSliceStart();
    if (earliest == null) return null;
    return DateTime(earliest.year, earliest.month, earliest.day);
  }

  /// Calendar-safe day increment (immune to DST shifts).
  static DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  /// Local minutes since midnight — the only part of the timestamp that
  /// means anything once the day is rolled up.
  static int? _minuteOfDay(DateTime? at) =>
      at == null ? null : at.hour * 60 + at.minute;

  void dispose() => _timer?.cancel();
}
