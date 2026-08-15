// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/core/models/activity.dart';
import 'package:restifeye/data/rollup_repository.dart';
import 'package:restifeye/services/insights.dart';
import 'package:flutter_test/flutter_test.dart';

DayRollup pastDay(int dayOfMonth, List<int> activeByHour) => (
  day: DateTime(2026, 6, dayOfMonth),
  screen: Duration(seconds: activeByHour.fold(0, (a, b) => a + b)),
  idle: Duration.zero,
  watch: Duration.zero,
  away: Duration.zero,
  longestStretch: Duration.zero,
  focusRuns: 0,
  firstActivityMinute: null,
  lastActivityMinute: null,
  activeByHour: activeByHour,
  completed: 0,
  credited: 0,
  escaped: 0,
  snoozes: 0,
);

/// An hourly profile with [minutes] of hands-on time in every hour from 9.
List<int> fromNine(int minutes) => [
  for (var h = 0; h < 24; h++) h >= 9 ? minutes * 60 : 0,
];

List<HourBand> bandsFromNine(int minutes) =>
    hourBandsFromActive(fromNine(minutes));

void main() {
  test('compares like for like, only over hours already finished', () {
    // Typically 40 minutes an hour from 09:00; today 50. By 12:00 three
    // hours have finished, so today is 30 minutes ahead — not 40 * a full
    // day's worth of hours the day has not reached yet.
    final pace = paceAgainstTypical(
      today: bandsFromNine(50),
      history: [for (var d = 1; d <= 5; d++) pastDay(d, fromNine(40))],
      completedHours: 12,
    );

    expect(pace!.typical, const Duration(minutes: 120));
    expect(pace.difference, const Duration(minutes: 30));
  });

  test('reports being behind as a negative difference', () {
    final pace = paceAgainstTypical(
      today: bandsFromNine(10),
      history: [for (var d = 1; d <= 5; d++) pastDay(d, fromNine(40))],
      completedHours: 11,
    );
    expect(pace!.difference, const Duration(minutes: -60));
  });

  // Comparing a half-finished day against whole-day averages would say "you
  // are behind" every single morning, which is both wrong and dispiriting.
  test('says nothing before the first hour of the day has finished', () {
    final pace = paceAgainstTypical(
      today: bandsFromNine(50),
      history: [for (var d = 1; d <= 5; d++) pastDay(d, fromNine(40))],
      completedHours: 0,
    );
    expect(pace, isNull);
  });

  test('says nothing on too little history', () {
    final pace = paceAgainstTypical(
      today: bandsFromNine(50),
      history: [pastDay(1, fromNine(40)), pastDay(2, fromNine(40))],
      completedHours: 12,
    );
    expect(pace, isNull);
  });

  test('ignores days recorded before the hourly profile existed', () {
    final pace = paceAgainstTypical(
      today: bandsFromNine(50),
      history: [
        for (var d = 1; d <= 5; d++) pastDay(d, const []),
        for (var d = 6; d <= 8; d++) pastDay(d, fromNine(40)),
      ],
      completedHours: 12,
    );
    // Only the three days that have a profile may be averaged.
    expect(pace!.typical, const Duration(minutes: 120));
  });
}
