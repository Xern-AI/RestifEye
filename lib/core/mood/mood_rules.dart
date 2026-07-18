import 'mood.dart';

/// What happened to a break the user was offered.
enum BreakResponse { honored, snoozed, skipped, escaped }

/// Everything the mood rules are allowed to see.
///
/// Deliberately a *rolling window* of recent responses rather than day
/// totals: judging on totals means one bad morning colours the icon red
/// until midnight, and a good afternoon can never earn its way back.
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
  /// credited).
  final Duration sinceLastRest;

  final bool inBreak;
  final bool paused;
}

/// Thresholds, gathered so they can be reasoned about (and tuned) in one
/// place instead of being scattered through the branches below.
class MoodRules {
  const MoodRules({
    this.window = 5,
    this.ignoringMisses = 3,
    this.slippingMisses = 2,
    this.slippingSnoozes = 3,
    this.greatHonorRate = 0.8,
    this.tiredAfterRest = const Duration(minutes: 90),
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

  /// No real rest for this long reads as tired...
  final Duration tiredAfterRest;

  /// ...as does a long day, even a compliant one.
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
/// the icon should say the day has been long.
Mood _fatigueOr(Mood base, MoodInputs inputs, MoodRules rules) {
  final overdue = inputs.sinceLastRest >= rules.tiredAfterRest;
  final longDay = inputs.screenTime >= rules.tiredAfterScreenTime;
  return overdue || longDay ? Mood.tired : base;
}
