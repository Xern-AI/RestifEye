import 'package:breaktime/data/rollup_repository.dart';
import 'package:breaktime/services/advice_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DayRollup day(
  int dayOfMonth, {
  int screenMinutes = 300,
  int idleMinutes = 60,
  int awayMinutes = 30,
  int stretchMinutes = 45,
  int completed = 8,
  int credited = 2,
  int escaped = 0,
  int snoozes = 2,
}) => (
  day: DateTime(2026, 6, dayOfMonth),
  screen: Duration(minutes: screenMinutes),
  idle: Duration(minutes: idleMinutes),
  away: Duration(minutes: awayMinutes),
  longestStretch: Duration(minutes: stretchMinutes),
  firstActivityMinute: 9 * 60,
  lastActivityMinute: 18 * 60,
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
}
