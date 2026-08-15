// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/data/rollup_repository.dart';
import 'package:restifeye/services/insights.dart';
import 'package:flutter_test/flutter_test.dart';

DayRollup day(
  int dayOfMonth, {
  int activeMinutes = 300,
  int idleMinutes = 60,
  int watchMinutes = 30,
  int awayMinutes = 45,
  int stretchMinutes = 50,
  int focusRuns = 4,
  int completed = 12,
  int credited = 1,
  int escaped = 0,
  int snoozes = 2,
  List<int>? activeByHour,
}) => (
  day: DateTime(2026, 6, dayOfMonth),
  screen: Duration(minutes: activeMinutes),
  idle: Duration(minutes: idleMinutes),
  watch: Duration(minutes: watchMinutes),
  away: Duration(minutes: awayMinutes),
  longestStretch: Duration(minutes: stretchMinutes),
  focusRuns: focusRuns,
  firstActivityMinute: 9 * 60,
  lastActivityMinute: 18 * 60,
  activeByHour: activeByHour ?? const [],
  completed: completed,
  credited: credited,
  escaped: escaped,
  snoozes: snoozes,
);

/// An hourly profile with [lateMinutes] of the day's work after 22:00.
List<int> profile({int dayMinutes = 300, int lateMinutes = 0}) => [
  for (var h = 0; h < 24; h++)
    if (h == 22)
      lateMinutes * 60
    else if (h >= 9 && h < 18)
      dayMinutes * 60 ~/ 9
    else
      0,
];

void main() {
  group('summarise', () {
    // A fortnight off is not a health improvement, and a holiday is not a
    // productivity collapse.
    test('averages over active days only, ignoring days off', () {
      final summary = summarise([
        day(1, activeMinutes: 300),
        day(2, activeMinutes: 0),
        day(3, activeMinutes: 0),
        day(4, activeMinutes: 360),
      ]);

      expect(summary.activeDays, 2);
      expect(summary.avgActive, const Duration(minutes: 330));
    });

    test('at-computer time includes watching', () {
      final summary = summarise([
        for (var d = 1; d <= 3; d++)
          day(d, activeMinutes: 300, idleMinutes: 60, watchMinutes: 30),
      ]);
      expect(summary.avgAtComputer, const Duration(minutes: 390));
    });

    test('reports no hourly data when no day carries a profile', () {
      final summary = summarise([for (var d = 1; d <= 4; d++) day(d)]);
      expect(summary.hasHourly, isFalse);
      expect(summary.avgAfterHours, Duration.zero);
    });

    test('averages late work over the days that can answer for it', () {
      final summary = summarise([
        day(1, activeByHour: profile(lateMinutes: 60)),
        day(2, activeByHour: profile(lateMinutes: 0)),
        day(3), // no profile: must not drag the average down
      ]);
      expect(summary.hasHourly, isTrue);
      expect(summary.avgAfterHours, const Duration(minutes: 30));
    });
  });

  group('rest score', () {
    const config = BreakConfig();

    test('stays silent on fewer than three days', () {
      expect(scorePeriod([day(1), day(2)], config), isNull);
    });

    test('a well-rested fortnight scores highly', () {
      final score = scorePeriod([
        for (var d = 1; d <= 14; d++)
          day(
            d,
            activeMinutes: 300,
            stretchMinutes: 45,
            completed: 18,
            escaped: 0,
            activeByHour: profile(),
          ),
      ], config);

      expect(score!.total, greaterThanOrEqualTo(85));
      expect(score.band, 'Excellent');
    });

    test('skipping breaks costs the most, and is named as the weak spot', () {
      final score = scorePeriod([
        for (var d = 1; d <= 14; d++)
          day(
            d,
            completed: 3,
            credited: 0,
            escaped: 12,
            activeByHour: profile(),
          ),
      ], config);

      expect(score!.total, lessThan(60));
      expect(score.weakest!.label, 'Breaks taken');
    });

    test('marathon runs are penalised even with perfect compliance', () {
      final good = scorePeriod([
        for (var d = 1; d <= 14; d++)
          day(d, stretchMinutes: 40, activeByHour: profile()),
      ], config);
      final marathon = scorePeriod([
        for (var d = 1; d <= 14; d++)
          day(d, stretchMinutes: 200, activeByHour: profile()),
      ], config);

      expect(marathon!.total, lessThan(good!.total));
      expect(marathon.weakest!.label, 'Unbroken runs');
    });

    // The score must not quietly change meaning when a component is missing.
    test('drops the hours component when no day has an hourly profile', () {
      final score = scorePeriod([for (var d = 1; d <= 5; d++) day(d)], config);
      expect(
        score!.parts.map((p) => p.label),
        isNot(contains('Sensible hours')),
      );
    });

    test('late nights pull the score down', () {
      final sensible = scorePeriod([
        for (var d = 1; d <= 10; d++) day(d, activeByHour: profile()),
      ], config);
      final nocturnal = scorePeriod([
        for (var d = 1; d <= 10; d++)
          day(d, activeByHour: profile(dayMinutes: 120, lateMinutes: 180)),
      ], config);

      expect(nocturnal!.total, lessThan(sensible!.total));
    });
  });

  group('weekday × hour profile', () {
    test('averages each weekday over its own occurrences', () {
      // 2026-06-01 is a Monday; days 1 and 8 are both Mondays.
      final grid = weekdayHourProfile([
        day(1, activeByHour: profile(dayMinutes: 180)),
        day(8, activeByHour: profile(dayMinutes: 360)),
        day(2, activeByHour: profile(dayMinutes: 90)),
      ]);

      expect(grid, hasLength(7));
      // Monday 09:00 averages the two Mondays: (20 + 40) / 2 minutes.
      expect(grid[0][9], (180 * 60 ~/ 9 + 360 * 60 ~/ 9) / 2);
      expect(grid[1][9], 90 * 60 ~/ 9);
      expect(grid[6][9], 0); // no Sunday recorded
    });

    test('is empty when no day carries a profile', () {
      expect(weekdayHourProfile([day(1), day(2)]), isEmpty);
    });
  });
}
