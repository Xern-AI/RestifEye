import '../data/rollup_repository.dart';

class Advice {
  const Advice({
    required this.ruleId,
    required this.title,
    required this.body,
    this.positive = false,
  });

  final String ruleId;
  final String title;
  final String body;

  /// Celebrations render differently from suggestions.
  final bool positive;
}

double _compliance(DayRollup day) {
  final total = day.completed + day.credited + day.escaped;
  return total == 0 ? 1.0 : (day.completed + day.credited) / total;
}

/// Evaluates all advice rules over recent [rollups] (oldest first, ideally
/// ~4 weeks). Pure function: same input, same advice. Order = priority.
List<Advice> evaluateAdvice(List<DayRollup> rollups) {
  final advice = <Advice>[];
  final active = rollups.where((r) => r.screen > Duration.zero).toList();
  if (active.length < 3) {
    return const [
      Advice(
        ruleId: 'collecting',
        title: 'Still learning your rhythm',
        body:
            'Advice appears after a few days of use. Keep RestifEye '
            'running and check back soon.',
        positive: true,
      ),
    ];
  }

  // --- streak celebration (highest priority when earned) ---------------
  var streak = 0;
  for (final day in active.reversed) {
    if (_compliance(day) >= 0.8) {
      streak++;
    } else {
      break;
    }
  }
  if (streak >= 5) {
    advice.add(
      Advice(
        ruleId: 'streak',
        title: '$streak-day break streak',
        body:
            'You completed at least 80% of your breaks $streak days in a '
            'row. Your eyes and back thank you.',
        positive: true,
      ),
    );
  }

  // --- marathon focus stretches ----------------------------------------
  final avgStretch =
      active.map((r) => r.longestStretch.inMinutes).reduce((a, b) => a + b) ~/
      active.length;
  if (avgStretch >= 90) {
    advice.add(
      Advice(
        ruleId: 'long_stretch',
        title: 'Marathon sessions detected',
        body:
            'Your longest unbroken stretch averages $avgStretch minutes. '
            'Eye strain builds fast past the hour mark — consider a shorter '
            'eye-break interval in Settings.',
      ),
    );
  }

  // --- snooze pressure ---------------------------------------------------
  final totalBreaks = active.fold(0, (n, r) => n + r.completed + r.escaped);
  final totalSnoozes = active.fold(0, (n, r) => n + r.snoozes);
  if (totalBreaks >= 10 && totalSnoozes > totalBreaks * 0.6) {
    advice.add(
      const Advice(
        ruleId: 'snooze_heavy',
        title: 'Lots of snoozing',
        body:
            'You snooze most breaks before taking them. That usually means '
            'the interval interrupts mid-task — try lengthening it slightly; '
            'a break you take beats three you snooze.',
      ),
    );
  }

  // --- escapes -----------------------------------------------------------
  final totalCompleted = active.fold(0, (n, r) => n + r.completed);
  final totalEscaped = active.fold(0, (n, r) => n + r.escaped);
  if (totalEscaped >= 3 && totalEscaped * 2 > totalCompleted) {
    advice.add(
      const Advice(
        ruleId: 'escape_heavy',
        title: 'The escape hatch is getting a workout',
        body:
            'You skip a large share of breaks with the emergency escape. '
            'If breaks land at bad moments, adjust work hours or intervals — '
            'skipping defeats the purpose.',
      ),
    );
  }

  // --- weekday pattern (needs ~2 weeks) ----------------------------------
  if (active.length >= 10) {
    final byWeekday = <int, List<double>>{};
    for (final day in active) {
      byWeekday.putIfAbsent(day.day.weekday, () => []).add(_compliance(day));
    }
    String? worstName;
    var worstAvg = 1.0;
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday', //
    ];
    byWeekday.forEach((weekday, values) {
      if (values.length < 2) return;
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (avg < worstAvg) {
        worstAvg = avg;
        worstName = names[weekday - 1];
      }
    });
    if (worstName != null && worstAvg < 0.6) {
      advice.add(
        Advice(
          ruleId: 'weekday_pattern',
          title: '${worstName}s are your hardest day',
          body:
              'Break compliance drops to ${(worstAvg * 100).round()}% on '
              '${worstName}s. Heavy meeting load? RestifEye already defers '
              'during calls — but if the day is just packed, a gentler '
              'schedule beats skipped breaks.',
        ),
      );
    }
  }

  // --- screen time trend (needs 2 weeks) ----------------------------------
  if (active.length >= 14) {
    final recent = active.sublist(active.length - 7);
    final previous = active.sublist(active.length - 14, active.length - 7);
    final recentAvg =
        recent.fold(0, (n, r) => n + r.screen.inMinutes) / recent.length;
    final previousAvg =
        previous.fold(0, (n, r) => n + r.screen.inMinutes) / previous.length;
    if (previousAvg > 60 && recentAvg > previousAvg * 1.2) {
      advice.add(
        Advice(
          ruleId: 'screen_trend',
          title: 'Screen time is climbing',
          body:
              'This week averages ${(recentAvg / 60).toStringAsFixed(1)} h '
              'of screen time per day — up '
              '${((recentAvg / previousAvg - 1) * 100).round()}% from last '
              'week. Worth a look at what changed.',
        ),
      );
    }
  }

  if (advice.isEmpty) {
    advice.add(
      const Advice(
        ruleId: 'all_good',
        title: 'Nothing to fix',
        body: 'Your break habits look healthy. Keep it up.',
        positive: true,
      ),
    );
  }
  return advice;
}
