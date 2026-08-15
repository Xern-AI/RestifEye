// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import '../core/models/activity.dart';
import '../core/models/break_config.dart';
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

/// Everything the analytics screen needs about one stretch of days.
///
/// Averages are over *active* days only. Including the days the machine was
/// off would report a holiday as a productivity collapse, and a fortnight
/// off as a health improvement.
typedef PeriodSummary = ({
  int activeDays,
  Duration avgActive,
  Duration avgAtComputer,
  Duration avgWatch,
  Duration avgIdle,
  Duration avgAway,
  Duration avgLongestStretch,
  Duration avgAfterHours,
  double activeShare,
  double compliance,
  double breaksPerDay,
  double focusRunsPerDay,
  int? typicalStartMinute,
  int? typicalEndMinute,
  bool hasHourly,
});

const PeriodSummary emptySummary = (
  activeDays: 0,
  avgActive: Duration.zero,
  avgAtComputer: Duration.zero,
  avgWatch: Duration.zero,
  avgIdle: Duration.zero,
  avgAway: Duration.zero,
  avgLongestStretch: Duration.zero,
  avgAfterHours: Duration.zero,
  activeShare: 0,
  compliance: 1,
  breaksPerDay: 0,
  focusRunsPerDay: 0,
  typicalStartMinute: null,
  typicalEndMinute: null,
  hasHourly: false,
);

/// Hands-on seconds falling outside 07:00–22:00 on one day.
int _afterHoursOf(DayRollup day) {
  if (day.activeByHour.length != 24) return 0;
  var seconds = 0;
  for (var hour = 0; hour < 24; hour++) {
    if (hour < 7 || hour >= 22) seconds += day.activeByHour[hour];
  }
  return seconds;
}

PeriodSummary summarise(List<DayRollup> days) {
  final active = days.where((d) => d.screen > Duration.zero).toList();
  if (active.isEmpty) return emptySummary;
  final count = active.length;

  Duration mean(int Function(DayRollup) seconds) =>
      Duration(seconds: active.fold(0, (sum, d) => sum + seconds(d)) ~/ count);

  final avgActive = mean((d) => d.screen.inSeconds);
  final avgAtComputer = mean((d) => atComputerOf(d).inSeconds);
  final withHours = active.where((d) => d.activeByHour.length == 24).toList();
  final withSpan = active.where((d) => d.firstActivityMinute != null).toList();

  final taken = active.fold(0, (n, d) => n + d.completed + d.credited);
  final concluded = taken + active.fold(0, (n, d) => n + d.escaped);

  return (
    activeDays: count,
    avgActive: avgActive,
    avgAtComputer: avgAtComputer,
    avgWatch: mean((d) => d.watch.inSeconds),
    avgIdle: mean((d) => d.idle.inSeconds),
    avgAway: mean((d) => d.away.inSeconds),
    avgLongestStretch: mean((d) => d.longestStretch.inSeconds),
    avgAfterHours: withHours.isEmpty
        ? Duration.zero
        : Duration(
            seconds:
                withHours.fold(0, (sum, d) => sum + _afterHoursOf(d)) ~/
                withHours.length,
          ),
    activeShare: avgAtComputer.inSeconds == 0
        ? 0
        : avgActive.inSeconds / avgAtComputer.inSeconds,
    compliance: concluded == 0 ? 1 : taken / concluded,
    breaksPerDay: taken / count,
    focusRunsPerDay: active.fold(0, (n, d) => n + d.focusRuns) / count,
    typicalStartMinute: withSpan.isEmpty
        ? null
        : withSpan.fold(0, (n, d) => n + d.firstActivityMinute!) ~/
              withSpan.length,
    typicalEndMinute: withSpan.isEmpty
        ? null
        : withSpan.fold(0, (n, d) => n + d.lastActivityMinute!) ~/
              withSpan.length,
    hasHourly: withHours.isNotEmpty,
  );
}

/// One weighted component of the rest score.
typedef ScorePart = ({
  String label,
  double value,
  double weight,
  String detail,
  String advice,
});

/// How well the period was rested, 0–100, and what made it so.
///
/// Deliberately scores only what the user controls about *resting*: whether
/// due breaks were taken, how often, how long the unbroken runs got, and how
/// much work landed late at night. It never scores how much they worked —
/// a long day is a fact about their job, not a failing, and an app that
/// grades it becomes one more thing to feel bad about.
class RestScore {
  const RestScore(this.parts);

  final List<ScorePart> parts;

  int get total {
    final weight = parts.fold(0.0, (sum, p) => sum + p.weight);
    if (weight == 0) return 0;
    final score = parts.fold(0.0, (sum, p) => sum + p.value * p.weight);
    return (score / weight * 100).round();
  }

  String get band => switch (total) {
    >= 85 => 'Excellent',
    >= 70 => 'Good',
    >= 50 => 'Fair',
    _ => 'Needs work',
  };

  /// The component costing the most points — the honest answer to "where do
  /// I need to do better", rather than the one that is easiest to say.
  ScorePart? get weakest {
    if (parts.isEmpty) return null;
    return parts.reduce(
      (a, b) => (1 - a.value) * a.weight >= (1 - b.value) * b.weight ? a : b,
    );
  }
}

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// Scores a period. Returns null with too little to judge — a single day is
/// not a habit, and a grade off one day would swing wildly and mean nothing.
RestScore? scorePeriod(List<DayRollup> days, BreakConfig config) {
  final active = days.where((d) => d.screen > Duration.zero).toList();
  if (active.length < 3) return null;

  final summary = summarise(active);
  final parts = <ScorePart>[];

  final taken = active.fold(0, (n, d) => n + d.completed + d.credited);
  final concluded = taken + active.fold(0, (n, d) => n + d.escaped);
  if (concluded > 0) {
    parts.add((
      label: 'Breaks taken',
      value: _clamp01(taken / concluded),
      weight: 0.4,
      detail: '${(taken / concluded * 100).round()}% of due breaks rested',
      advice:
          'Breaks are coming due and going untaken. If they keep landing '
          'mid-task, a slightly longer interval you honour beats a short '
          'one you skip.',
    ));
  }

  // How many rests the schedule asked for, against how many happened. A
  // perfect completion rate means little if the timer was paused all day.
  final expected =
      summary.avgAtComputer.inSeconds *
      active.length /
      max(1, config.microInterval.inSeconds);
  if (expected >= 3) {
    parts.add((
      label: 'How often',
      value: _clamp01(taken / expected),
      weight: 0.25,
      detail:
          '${summary.breaksPerDay.toStringAsFixed(1)} rests a day at the '
          'machine',
      advice:
          'You are at the machine for longer than your breaks are covering '
          '— time is going by while the timer is paused or the app is '
          'closed.',
    ));
  }

  // Unbroken runs measured against the long-break interval: the point of
  // the schedule is that no run should reach much past it.
  final target = config.longInterval.inSeconds;
  parts.add((
    label: 'Unbroken runs',
    value: _clamp01(
      1 - (summary.avgLongestStretch.inSeconds - target) / max(1, target),
    ),
    weight: 0.2,
    detail: 'longest run averages ${summary.avgLongestStretch.inMinutes} min',
    advice:
        'Your longest daily stretch runs well past the interval you set. '
        'Eye strain and stiffness build fastest in exactly those runs.',
  ));

  if (summary.hasHourly && summary.avgActive > Duration.zero) {
    final share = summary.avgAfterHours.inSeconds / summary.avgActive.inSeconds;
    parts.add((
      label: 'Sensible hours',
      value: _clamp01(1 - share / 0.25),
      weight: 0.15,
      detail: '${(share * 100).round()}% of work before 07:00 or after 22:00',
      advice:
          'A real share of your work is landing late at night or very '
          'early. That is the screen time that costs the most sleep.',
    ));
  }

  return RestScore(parts);
}

/// Average hands-on seconds for each weekday and hour: a 7 × 24 grid,
/// Monday first. Empty when no day in the range carries an hourly profile.
List<List<double>> weekdayHourProfile(List<DayRollup> days) {
  final totals = [for (var d = 0; d < 7; d++) List<double>.filled(24, 0)];
  final counts = List<int>.filled(7, 0);
  var any = false;

  for (final day in days) {
    if (day.activeByHour.length != 24) continue;
    any = true;
    final weekday = day.day.weekday - 1;
    counts[weekday]++;
    for (var hour = 0; hour < 24; hour++) {
      totals[weekday][hour] += day.activeByHour[hour];
    }
  }
  if (!any) return const [];

  for (var d = 0; d < 7; d++) {
    if (counts[d] == 0) continue;
    for (var h = 0; h < 24; h++) {
      totals[d][h] /= counts[d];
    }
  }
  return totals;
}
