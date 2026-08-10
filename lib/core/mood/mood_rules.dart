// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'mood.dart';
import 'mood_window.dart';

export 'mood_window.dart' show BreakResponse;

/// Everything the mood rules are allowed to see.
///
/// Deliberately a *rolling window* of recent responses rather than day
/// totals: judging on totals means one bad morning colours the icon red
/// until midnight, and a good afternoon can never earn its way back. See
/// [MoodWindow] for how that window is bounded.
class MoodInputs {
  const MoodInputs({
    this.recent = const [],
    this.screenTime = Duration.zero,
    this.sinceLastRest = Duration.zero,
    this.inBreak = false,
    this.paused = false,
  });

  /// Most recent responses, oldest first. Callers pass at most
  /// [MoodRules.window] entries; longer lists are truncated to it.
  final List<BreakResponse> recent;

  /// Active screen time so far today.
  final Duration screenTime;

  /// Time since the last break that actually happened (completed or
  /// credited). With none on record, how long the user has been at the
  /// screen — the honest lower bound on the current stretch.
  final Duration sinceLastRest;

  final bool inBreak;
  final bool paused;
}

/// Thresholds, gathered so they can be reasoned about (and tuned) in one
/// place instead of being scattered through the branches below.
class MoodRules {
  const MoodRules({
    this.window = MoodWindow.defaultSize,
    this.ignoringMisses = 3,
    this.slippingMisses = 2,
    this.slippingSnoozes = 3,
    this.greatHonorRate = 0.8,
    this.tiredAfterRest = const Duration(minutes: 90),
    this.tiredAfterRestOnLongDay = const Duration(minutes: 45),
    this.tiredAfterScreenTime = const Duration(hours: 6),
  });

  /// How many recent responses the mood is judged on.
  final int window;

  /// Skips/escapes within the window that mean breaks are being ignored.
  final int ignoringMisses;

  /// Skips/escapes within the window that mean breaks are slipping.
  final int slippingMisses;

  /// Snoozes alone are mild; this many in the window still counts as
  /// slipping.
  final int slippingSnoozes;

  /// Fraction of the window that must be honored to earn [Mood.great].
  final double greatHonorRate;

  /// No real rest for this long reads as tired.
  final Duration tiredAfterRest;

  /// The same, once the day is already long — the bar drops rather than the
  /// icon latching. See [_fatigueOr].
  final Duration tiredAfterRestOnLongDay;

  /// How much screen time makes a day "long".
  final Duration tiredAfterScreenTime;
}

/// Maps behaviour to a face. Pure: same inputs, same mood, always.
///
/// Precedence is deliberate. The two transient states win outright — the
/// icon must reflect what is happening right now before it reflects a
/// pattern. Among the behavioural moods the most actionable wins: being
/// told you are ignoring breaks matters more than being told the day is
/// long, and both matter more than praise.
Mood computeMood(MoodInputs inputs, {MoodRules rules = const MoodRules()}) {
  if (inputs.paused) return Mood.paused;
  if (inputs.inBreak) return Mood.resting;

  final recent = inputs.recent.length > rules.window
      ? inputs.recent.sublist(inputs.recent.length - rules.window)
      : inputs.recent;

  // No history yet: a fresh install, or the first break of the day. Withhold
  // judgement rather than inventing an opinion from nothing.
  if (recent.isEmpty) return _fatigueOr(Mood.good, inputs, rules);

  // A skip and an escape are the same act — a break offered and refused. A
  // snooze is not: it is a deferral the app explicitly offers, so it only
  // counts once it becomes a habit.
  final misses = recent
      .where((r) => r == BreakResponse.skipped || r == BreakResponse.escaped)
      .length;
  final snoozes = recent.where((r) => r == BreakResponse.snoozed).length;
  final honored = recent.where((r) => r == BreakResponse.honored).length;

  if (misses >= rules.ignoringMisses) return Mood.ignoring;
  if (misses >= rules.slippingMisses || snoozes >= rules.slippingSnoozes) {
    return Mood.slipping;
  }

  final honorRate = honored / recent.length;
  final base = honorRate >= rules.greatHonorRate && misses == 0
      ? Mood.great
      : Mood.good;
  return _fatigueOr(base, inputs, rules);
}

/// Tiredness outranks "fine" and "great" but not the behavioural warnings:
/// someone taking every break on a nine-hour day is still doing well, but
/// the icon should say when they have been at it too long without a rest.
///
/// Tiredness is a *stretch*, never a total. Reading it off cumulative screen
/// time meant that once a day passed six hours the icon stayed tired for the
/// rest of it — including five seconds after a completed break, with a
/// tooltip asking for the break the user had just taken. A mood that cannot
/// be cleared by doing the right thing teaches people to ignore the icon,
/// which is the only thing it has.
///
/// A long day still counts, by lowering the bar rather than latching: after
/// [MoodRules.tiredAfterScreenTime] at the screen it takes only
/// [MoodRules.tiredAfterRestOnLongDay] without rest to read as tired. The app
/// gets more insistent as the day wears on, and a break still answers it.
Mood _fatigueOr(Mood base, MoodInputs inputs, MoodRules rules) {
  final longDay = inputs.screenTime >= rules.tiredAfterScreenTime;
  final threshold = longDay
      ? rules.tiredAfterRestOnLongDay
      : rules.tiredAfterRest;
  // Nobody can have been at the screen longer than they have been at the
  // screen today: without this, resting yesterday evening would read as a
  // sixteen-hour stretch at nine the next morning.
  final atScreenSinceRest = inputs.sinceLastRest < inputs.screenTime
      ? inputs.sinceLastRest
      : inputs.screenTime;
  return atScreenSinceRest >= threshold ? Mood.tired : base;
}
