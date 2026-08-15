// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../core/models/activity.dart';
import '../data/rollup_repository.dart';

/// How today is going against a typical day, measured at the same point in
/// the day rather than against a whole one.
typedef Pace = ({Duration typical, Duration difference});

/// At least this many past days with an hourly profile before a comparison
/// is worth making. Two days is an anecdote.
const _minimumHistory = 3;

/// Compares today's hands-on time with the same stretch of a typical recent
/// day.
///
/// Comparing a half-finished day against completed-day averages says "you
/// are behind" every morning, which is both useless and discouraging. Only
/// whole hours already past are counted, on both sides, so the comparison is
/// like for like. Returns null when there is nothing fair to compare
/// against: too little history, or too early in the day.
Pace? paceAgainstTypical({
  required List<HourBand> today,
  required List<DayRollup> history,
  required int completedHours,
}) {
  if (completedHours <= 0 || today.length != 24) return null;

  final usable = history
      .where(
        (day) => day.activeByHour.length == 24 && day.screen > Duration.zero,
      )
      .toList();
  if (usable.length < _minimumHistory) return null;

  var typicalSeconds = 0;
  for (final day in usable) {
    for (var hour = 0; hour < completedHours; hour++) {
      typicalSeconds += day.activeByHour[hour];
    }
  }
  typicalSeconds ~/= usable.length;

  var todaySeconds = 0;
  for (var hour = 0; hour < completedHours; hour++) {
    todaySeconds += today[hour].active;
  }

  return (
    typical: Duration(seconds: typicalSeconds),
    difference: Duration(seconds: todaySeconds - typicalSeconds),
  );
}
