// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

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

/// How many suggestions are worth showing at once.
///
/// A page of a dozen things to fix is a page nobody acts on. The rules are
/// evaluated in priority order and the list is cut here, so what survives is
/// what matters most — praise is exempt, since it is short and it is the
/// reason people come back.
const _maxSuggestions = 4;

double _compliance(DayRollup day) {
  final total = day.completed + day.credited + day.escaped;
  return total == 0 ? 1.0 : (day.completed + day.credited) / total;
}

/// Whether this day was rolled up by a version that recorded watch time and
/// the hourly profile. Older rows default those columns to zero, which is
/// indistinguishable from a genuinely quiet day — so any rule reading them
/// must skip days that predate them rather than accuse the user of
/// something the data cannot support.
bool _detailed(DayRollup day) => day.activeByHour.length == 24;

int _afterHours(DayRollup day) {
  var seconds = 0;
  for (var hour = 0; hour < 24; hour++) {
    if (hour < 7 || hour >= 22) seconds += day.activeByHour[hour];
  }
  return seconds;
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

  final detailed = active.where(_detailed).toList();

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

  // --- week-on-week compliance movement ---------------------------------
  if (active.length >= 10) {
    final half = active.length ~/ 2;
    final earlier = active.take(half);
    final later = active.skip(half);
    final was =
        earlier.map(_compliance).reduce((a, b) => a + b) / earlier.length;
    final now = later.map(_compliance).reduce((a, b) => a + b) / later.length;

    if (now - was >= 0.15) {
      advice.add(
        Advice(
          ruleId: 'improving',
          title: 'You are taking more of your breaks',
          body:
              'Break compliance is up from ${(was * 100).round()}% to '
              '${(now * 100).round()}% over this stretch. Whatever changed, '
              'it is working.',
          positive: true,
        ),
      );
    } else if (was - now >= 0.15) {
      advice.add(
        Advice(
          ruleId: 'slipping',
          title: 'Break habits are slipping',
          body:
              'You were resting ${(was * 100).round()}% of due breaks and '
              'are now at ${(now * 100).round()}%. Worth catching early — '
              'this is usually a busy patch rather than a decision.',
        ),
      );
    }
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

  // --- late nights -------------------------------------------------------
  if (detailed.length >= 5) {
    final activeSeconds = detailed.fold(0, (n, r) => n + r.screen.inSeconds);
    final lateSeconds = detailed.fold(0, (n, r) => n + _afterHours(r));
    if (activeSeconds > 0 && lateSeconds > activeSeconds * 0.15) {
      final perDay = Duration(seconds: lateSeconds ~/ detailed.length);
      advice.add(
        Advice(
          ruleId: 'late_night',
          title: 'A lot of this is happening late',
          body:
              '${(lateSeconds / activeSeconds * 100).round()}% of your work '
              'lands before 07:00 or after 22:00 — about ${perDay.inMinutes} '
              'minutes a day. Screen time close to bed is the kind that '
              'costs you sleep as well as your eyes.',
        ),
      );
    }
  }

  // --- watching vs working ------------------------------------------------
  if (detailed.length >= 5) {
    final watch = detailed.fold(0, (n, r) => n + r.watch.inSeconds);
    final atComputer = detailed.fold(
      0,
      (n, r) => n + atComputerOf(r).inSeconds,
    );
    if (atComputer > 0 && watch > atComputer * 0.3) {
      advice.add(
        Advice(
          ruleId: 'watch_heavy',
          title: 'A third of your screen time is watching',
          body:
              '${(watch / atComputer * 100).round()}% of your time at this '
              'machine is video, calls or slides rather than hands-on work. '
              'Your eyes do not know the difference — the same 20-20-20 '
              'rule applies, which is why breaks still come due.',
        ),
      );
    }
  }

  // --- no deep work ------------------------------------------------------
  final substantial = detailed
      .where((r) => r.screen >= const Duration(hours: 3))
      .toList();
  if (substantial.length >= 5) {
    final fragmented = substantial.where((r) => r.focusRuns == 0).length;
    if (fragmented > substantial.length * 0.6) {
      advice.add(
        Advice(
          ruleId: 'fragmented',
          title: 'Your days are arriving in fragments',
          body:
              'On $fragmented of your last ${substantial.length} full days, '
              'no stretch of work reached 25 unbroken minutes. That is not a '
              'break problem — but if it is not what you wanted, the pause '
              'control on the dashboard buys you a quiet hour.',
        ),
      );
    }
  }

  // --- irregular start times ---------------------------------------------
  final starts = active
      .where((r) => r.firstActivityMinute != null)
      .map((r) => r.firstActivityMinute!)
      .toList();
  if (starts.length >= 8) {
    final mean = starts.reduce((a, b) => a + b) / starts.length;
    final spread = sqrt(
      starts.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) /
          starts.length,
    );
    if (spread >= 120) {
      advice.add(
        Advice(
          ruleId: 'irregular_start',
          title: 'Your day starts at a different time each day',
          body:
              'Your start time swings by about ${(spread / 60).round()} hours '
              'either side of ${_clock(mean.round())}. Work hours in Settings '
              'only help when the day is predictable — if yours is not, leave '
              'them off rather than fighting them.',
        ),
      );
    }
  }

  // --- weekends ----------------------------------------------------------
  final weekends = active
      .where(
        (r) =>
            r.day.weekday >= DateTime.saturday &&
            r.screen >= const Duration(hours: 2),
      )
      .length;
  if (weekends >= 4) {
    advice.add(
      Advice(
        ruleId: 'weekend_work',
        title: 'The weekend is a work day too',
        body:
            'You have put in two hours or more on $weekends weekend days '
            'recently. RestifEye runs every day by default — if you would '
            'rather it left you alone at the weekend, turn those days off '
            'in Settings.',
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

  // Praise is kept whole; suggestions are cut to the ones worth acting on.
  final praise = advice.where((a) => a.positive);
  final suggestions = advice.where((a) => !a.positive).take(_maxSuggestions);
  return [...praise, ...suggestions];
}

String _clock(int minuteOfDay) {
  final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
