// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/data/rollup_repository.dart';
import 'package:restifeye/services/advice_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DayRollup day(
  int dayOfMonth, {
  int screenMinutes = 300,
  int idleMinutes = 60,
  int watchMinutes = 20,
  int awayMinutes = 30,
  int stretchMinutes = 45,
  int focusRuns = 3,
  int firstMinute = 9 * 60,
  int lastMinute = 18 * 60,
  List<int> activeByHour = const [],
  int completed = 8,
  int credited = 2,
  int escaped = 0,
  int snoozes = 2,
}) => (
  day: DateTime(2026, 6, dayOfMonth),
  screen: Duration(minutes: screenMinutes),
  idle: Duration(minutes: idleMinutes),
  watch: Duration(minutes: watchMinutes),
  away: Duration(minutes: awayMinutes),
  longestStretch: Duration(minutes: stretchMinutes),
  focusRuns: focusRuns,
  firstActivityMinute: firstMinute,
  lastActivityMinute: lastMinute,
  activeByHour: activeByHour,
  completed: completed,
  credited: credited,
  escaped: escaped,
  snoozes: snoozes,
);

void main() {
  test('asks for patience with under three days of data', () {
    final advice = evaluateAdvice([day(1), day(2)]);
    expect(advice.single.ruleId, 'collecting');
  });

  test('healthy data yields the all-good message', () {
    final advice = evaluateAdvice([for (var d = 1; d <= 4; d++) day(d)]);
    expect(advice.single.ruleId, 'all_good');
    expect(advice.single.positive, isTrue);
  });

  test('celebrates a 5+ day compliance streak', () {
    final advice = evaluateAdvice([for (var d = 1; d <= 6; d++) day(d)]);
    // 6 healthy days: streak fires (and suppresses all_good).
    expect(advice.first.ruleId, 'streak');
    expect(advice.first.title, contains('6-day'));
  });

  test('flags marathon focus stretches', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 4; d++) day(d, stretchMinutes: 120, completed: 2),
    ]);
    expect(advice.map((a) => a.ruleId), contains('long_stretch'));
  });

  test('flags heavy snoozing', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 4; d++) day(d, snoozes: 8, completed: 4),
    ]);
    expect(advice.map((a) => a.ruleId), contains('snooze_heavy'));
  });

  test('flags heavy escaping', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 4; d++)
        day(d, escaped: 4, completed: 3, credited: 0),
    ]);
    expect(advice.map((a) => a.ruleId), contains('escape_heavy'));
  });

  test('finds the worst weekday with two weeks of data', () {
    // Mondays (June 2026: 1st, 8th, 15th) are terrible; other days fine.
    final rollups = <DayRollup>[
      for (var d = 1; d <= 16; d++)
        DateTime(2026, 6, d).weekday == DateTime.monday
            ? day(d, escaped: 8, completed: 2, credited: 0)
            : day(d),
    ];
    final advice = evaluateAdvice(rollups);
    final weekday = advice.where((a) => a.ruleId == 'weekday_pattern').toList();
    expect(weekday, hasLength(1));
    expect(weekday.single.title, contains('Monday'));
  });

  test('flags a rising screen-time trend over two weeks', () {
    final rollups = <DayRollup>[
      for (var d = 1; d <= 7; d++) day(d, screenMinutes: 300),
      for (var d = 8; d <= 14; d++) day(d, screenMinutes: 420),
    ];
    final advice = evaluateAdvice(rollups);
    expect(advice.map((a) => a.ruleId), contains('screen_trend'));
  });

  test('ignores zero-screen days (machine off) instead of skewing stats', () {
    final advice = evaluateAdvice([
      day(1),
      day(2),
      day(3),
      day(4, screenMinutes: 0, completed: 0, credited: 0, snoozes: 0),
    ]);
    expect(advice.single.ruleId, 'all_good');
  });

  group('rules that need the hourly profile', () {
    /// A day's hands-on seconds by hour, with [lateMinutes] landing at 23:00.
    List<int> hours({int dayMinutes = 300, int lateMinutes = 0}) => [
      for (var h = 0; h < 24; h++)
        if (h == 23)
          lateMinutes * 60
        else if (h >= 9 && h < 18)
          dayMinutes * 60 ~/ 9
        else
          0,
    ];

    test('flags work landing late at night', () {
      final advice = evaluateAdvice([
        for (var d = 1; d <= 8; d++)
          day(
            d,
            screenMinutes: 300,
            activeByHour: hours(dayMinutes: 200, lateMinutes: 100),
          ),
      ]);
      expect(advice.map((a) => a.ruleId), contains('late_night'));
    });

    // The columns default to zero on days rolled up before they existed,
    // which is indistinguishable from a genuinely quiet day. Accusing the
    // user of something the data cannot support is worse than silence.
    test('says nothing about late nights on days with no profile', () {
      final advice = evaluateAdvice([for (var d = 1; d <= 8; d++) day(d)]);
      expect(advice.map((a) => a.ruleId), isNot(contains('late_night')));
    });

    test('flags a screen day that is mostly watching', () {
      final advice = evaluateAdvice([
        for (var d = 1; d <= 8; d++)
          day(
            d,
            screenMinutes: 120,
            idleMinutes: 30,
            watchMinutes: 240,
            activeByHour: hours(dayMinutes: 120),
          ),
      ]);
      expect(advice.map((a) => a.ruleId), contains('watch_heavy'));
    });

    test('flags full days that never reach an unbroken 25 minutes', () {
      final advice = evaluateAdvice([
        for (var d = 1; d <= 8; d++)
          day(d, screenMinutes: 300, focusRuns: 0, activeByHour: hours()),
      ]);
      expect(advice.map((a) => a.ruleId), contains('fragmented'));
    });
  });

  test('flags a start time that swings by hours', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 12; d++)
        day(d, firstMinute: d.isEven ? 6 * 60 : 14 * 60),
    ]);
    expect(advice.map((a) => a.ruleId), contains('irregular_start'));
  });

  test('offers to leave weekends alone once they are a habit', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 28; d++) day(d, screenMinutes: 240),
    ]);
    expect(advice.map((a) => a.ruleId), contains('weekend_work'));
  });

  test('celebrates compliance that is climbing', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 7; d++) day(d, completed: 3, escaped: 7),
      for (var d = 8; d <= 14; d++) day(d, completed: 10, escaped: 0),
    ]);
    expect(advice.map((a) => a.ruleId), contains('improving'));
  });

  test('warns when compliance is falling', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 7; d++) day(d, completed: 10, escaped: 0),
      for (var d = 8; d <= 14; d++) day(d, completed: 3, escaped: 7),
    ]);
    expect(advice.map((a) => a.ruleId), contains('slipping'));
  });

  // A dozen things to fix is a page nobody acts on.
  test('caps suggestions, but never trims the praise', () {
    final advice = evaluateAdvice([
      for (var d = 1; d <= 28; d++)
        day(
          d,
          screenMinutes: 480,
          stretchMinutes: 150,
          watchMinutes: 400,
          idleMinutes: 30,
          focusRuns: 0,
          completed: 2,
          credited: 0,
          escaped: 9,
          snoozes: 20,
          firstMinute: d.isEven ? 6 * 60 : 15 * 60,
          activeByHour: [
            for (var h = 0; h < 24; h++)
              if (h == 23) 7200 else if (h >= 9 && h < 18) 1800 else 0,
          ],
        ),
    ]);
    expect(advice.where((a) => !a.positive), hasLength(4));
  });
}
