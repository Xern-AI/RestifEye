// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// What the user was doing during a recorded time slice.
///
/// Stored by index, so values may only ever be appended — `watching` came
/// after the first three and must stay last.
///
/// The kinds are mutually exclusive by construction, which is what lets a
/// day be added up without double counting. `watching` is a *kind of idle*:
/// hands off the keyboard while something on screen holds an idle inhibitor.
/// Hands on the keyboard is `active` even with a video playing, because that
/// is what the person was actually doing.
enum SliceKind { active, idle, locked, watching }

/// A contiguous span of one activity kind.
class ActivitySlice {
  const ActivitySlice({
    required this.start,
    required this.end,
    required this.kind,
  });

  final DateTime start;
  final DateTime end;
  final SliceKind kind;

  Duration get length => end.difference(start);
}

/// What this second counts as.
///
/// Pure, and here rather than inside EngineService, because it is the single
/// rule that decides what every statistic in the app is made of — worth
/// stating in one place and testing without a compositor.
SliceKind classifySlice({
  required bool away,
  required Duration idle,
  required Duration idleThreshold,
  required bool presenting,
}) {
  if (away) return SliceKind.locked;
  // Hands on the keyboard is work even with a film playing: watching is what
  // you do once you have stopped typing, and deciding otherwise would let a
  // background video swallow a morning's work.
  if (idle < idleThreshold) return SliceKind.active;
  return presenting ? SliceKind.watching : SliceKind.idle;
}

/// Seconds of each kind falling inside one hour of the local day.
typedef HourBand = ({int active, int idle, int watching, int away});

const HourBand _emptyBand = (active: 0, idle: 0, watching: 0, away: 0);

/// A run of hands-on work at least this long counts as deep work. Twenty-five
/// minutes is the pomodoro, and short enough that a normal morning produces
/// several — a threshold nobody ever reaches measures nothing.
const focusRunMinimum = Duration(minutes: 25);

/// Hours outside which screen time is worth pointing out. Deliberately
/// generous: this flags genuinely late nights, not merely long days.
const _dayStartHour = 7;
const _dayEndHour = 22;

/// Aggregate stats for one day, computed from slices and break events.
class DayStats {
  const DayStats({
    this.screenTime = Duration.zero,
    this.idleTime = Duration.zero,
    this.watchTime = Duration.zero,
    this.awayTime = Duration.zero,
    this.longestStretch = Duration.zero,
    this.focusRuns = 0,
    this.hours = const [],
    this.firstActivity,
    this.lastActivity,
    this.breaksCompleted = 0,
    this.breaksCredited = 0,
    this.breaksEscaped = 0,
    this.snoozes = 0,
  });

  /// Time actually working: keyboard and mouse in use.
  final Duration screenTime;

  /// At the machine but not touching it — reading, thinking.
  final Duration idleTime;

  /// At the machine watching something: hands off while a video, call or
  /// presentation holds the screen awake. Split out of idle because "six
  /// hours at this computer" means something different when two of them
  /// were a film.
  final Duration watchTime;

  /// Locked or suspended: genuinely away from the desk.
  final Duration awayTime;

  /// The longest unbroken run of activity.
  final Duration longestStretch;

  /// How many unbroken runs reached [focusRunMinimum].
  final int focusRuns;

  /// Per-hour composition of the day, 24 entries, or empty when unknown.
  final List<HourBand> hours;

  /// First and last activity of the day — the span of the working day.
  final DateTime? firstActivity;
  final DateTime? lastActivity;

  final int breaksCompleted;
  final int breaksCredited;
  final int breaksEscaped;
  final int snoozes;

  /// Time in front of the machine, whether or not hands were moving.
  Duration get atComputer => screenTime + idleTime + watchTime;

  /// Share of time at the machine that was actually hands-on. Low is not bad
  /// — it is reading and thinking — so it is reported, never scored.
  double get activeRatio {
    final total = atComputer.inSeconds;
    return total == 0 ? 0 : screenTime.inSeconds / total;
  }

  /// Wall-clock span from first to last activity: when the day really ran.
  Duration? get workdaySpan {
    final (first, last) = (firstActivity, lastActivity);
    if (first == null || last == null) return null;
    return last.difference(first);
  }

  /// The hour of the local day with the most hands-on time, or null when
  /// nothing was recorded.
  int? get peakHour {
    if (hours.isEmpty) return null;
    var best = 0;
    for (var h = 1; h < hours.length; h++) {
      if (hours[h].active > hours[best].active) best = h;
    }
    return hours[best].active == 0 ? null : best;
  }

  /// Hands-on time before 07:00 or after 22:00.
  Duration get afterHours {
    if (hours.isEmpty) return Duration.zero;
    var seconds = 0;
    for (var h = 0; h < hours.length; h++) {
      if (h < _dayStartHour || h >= _dayEndHour) seconds += hours[h].active;
    }
    return Duration(seconds: seconds);
  }

  /// Fraction of concluded breaks actually rested (completed or credited).
  double get compliance {
    final total = breaksCompleted + breaksCredited + breaksEscaped;
    return total == 0 ? 1.0 : (breaksCompleted + breaksCredited) / total;
  }
}

class _HourAccumulator {
  int active = 0;
  int idle = 0;
  int watching = 0;
  int away = 0;

  HourBand get band =>
      (active: active, idle: idle, watching: watching, away: away);
}

/// Folds a day's slices into [DayStats].
///
/// Slices are assumed non-overlapping.
///
/// The longest stretch is the longest run of *adjoining* active slices, not
/// the longest single slice. [ActivityRecorder] is flushed once a minute for
/// crash-safety, which closes the open slice and starts a new one — so an
/// unbroken two-hour focus run is stored as ~120 one-minute slices. Reading
/// the longest single slice therefore reported "1m" forever. Where the writer
/// happened to checkpoint is a persistence detail and must not be visible in
/// the statistics.
DayStats computeSliceStats(Iterable<ActivitySlice> slices) {
  // Adjoining slices share an instant exactly (flush sets the next start to
  // the previous end), but tolerate a second of drift for suspend/NTP nudges.
  const adjoining = Duration(seconds: 1);

  final ordered = slices.toList()..sort((a, b) => a.start.compareTo(b.start));

  var screen = Duration.zero;
  var idle = Duration.zero;
  var watch = Duration.zero;
  var away = Duration.zero;
  var longest = Duration.zero;
  var focusRuns = 0;
  DateTime? first;
  DateTime? last;
  final hours = List.generate(24, (_) => _HourAccumulator());

  // The active run currently being accumulated.
  DateTime? runStart;
  DateTime? runEnd;

  void closeRun() {
    if (runStart == null) return;
    final length = runEnd!.difference(runStart!);
    if (length > longest) longest = length;
    if (length >= focusRunMinimum) focusRuns++;
    runStart = null;
    runEnd = null;
  }

  // A slice can straddle an hour boundary, so it is charged to each hour it
  // actually occupies rather than to the one it started in.
  void chargeHours(ActivitySlice slice) {
    var cursor = slice.start;
    while (cursor.isBefore(slice.end)) {
      final nextHour = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour,
      ).add(const Duration(hours: 1));
      final until = nextHour.isBefore(slice.end) ? nextHour : slice.end;
      final seconds = until.difference(cursor).inSeconds;
      final hour = hours[cursor.hour];
      switch (slice.kind) {
        case SliceKind.active:
          hour.active += seconds;
        case SliceKind.idle:
          hour.idle += seconds;
        case SliceKind.watching:
          hour.watching += seconds;
        case SliceKind.locked:
          hour.away += seconds;
      }
      cursor = until;
    }
  }

  for (final slice in ordered) {
    chargeHours(slice);
    switch (slice.kind) {
      case SliceKind.active:
        screen += slice.length;
        if (first == null || slice.start.isBefore(first)) first = slice.start;
        if (last == null || slice.end.isAfter(last)) last = slice.end;

        final continues =
            runEnd != null &&
            slice.start.difference(runEnd!).abs() <= adjoining;
        if (continues) {
          runEnd = slice.end;
        } else {
          closeRun();
          runStart = slice.start;
          runEnd = slice.end;
        }

      // Any pause in activity ends the stretch.
      case SliceKind.idle:
        idle += slice.length;
        closeRun();
      case SliceKind.watching:
        watch += slice.length;
        closeRun();
      case SliceKind.locked:
        away += slice.length;
        closeRun();
    }
  }
  closeRun();

  return DayStats(
    screenTime: screen,
    idleTime: idle,
    watchTime: watch,
    awayTime: away,
    longestStretch: longest,
    focusRuns: focusRuns,
    hours: [for (final hour in hours) hour.band],
    firstActivity: first,
    lastActivity: last,
  );
}

/// Rebuilds an hourly profile from stored per-hour active seconds, for days
/// whose raw slices have been pruned. Only the hands-on band survives the
/// rollup, so the rest read zero — which is the truth, not a guess.
List<HourBand> hourBandsFromActive(List<int> activeSeconds) => [
  for (var h = 0; h < 24; h++)
    h < activeSeconds.length
        ? (active: activeSeconds[h], idle: 0, watching: 0, away: 0)
        : _emptyBand,
];
