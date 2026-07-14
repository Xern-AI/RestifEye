/// What the user was doing during a recorded time slice.
enum SliceKind { active, idle, locked }

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

/// Aggregate stats for one day, computed from slices and break events.
class DayStats {
  const DayStats({
    this.screenTime = Duration.zero,
    this.idleTime = Duration.zero,
    this.awayTime = Duration.zero,
    this.longestStretch = Duration.zero,
    this.firstActivity,
    this.lastActivity,
    this.breaksCompleted = 0,
    this.breaksCredited = 0,
    this.breaksEscaped = 0,
    this.snoozes = 0,
  });

  /// Time actually working: keyboard and mouse in use.
  final Duration screenTime;

  /// At the machine but not touching it — reading, thinking, watching.
  final Duration idleTime;

  /// Locked or suspended: genuinely away from the desk.
  final Duration awayTime;

  /// The longest unbroken run of activity.
  final Duration longestStretch;

  /// First and last activity of the day — the span of the working day.
  final DateTime? firstActivity;
  final DateTime? lastActivity;

  final int breaksCompleted;
  final int breaksCredited;
  final int breaksEscaped;
  final int snoozes;

  /// Time in front of the machine, whether or not hands were moving.
  Duration get atComputer => screenTime + idleTime;

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

  /// Fraction of concluded breaks actually rested (completed or credited).
  double get compliance {
    final total = breaksCompleted + breaksCredited + breaksEscaped;
    return total == 0 ? 1.0 : (breaksCompleted + breaksCredited) / total;
  }
}

/// Folds a day's slices into [DayStats].
///
/// Every slice kind is now accounted for. Idle and locked spans were already
/// being recorded once per second and then discarded here, which is why the
/// app could show screen time but never answer "how much of today did I
/// actually spend at this machine?".
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
  var away = Duration.zero;
  var longest = Duration.zero;
  DateTime? first;
  DateTime? last;

  // The active run currently being accumulated.
  DateTime? runStart;
  DateTime? runEnd;

  void closeRun() {
    if (runStart == null) return;
    final length = runEnd!.difference(runStart!);
    if (length > longest) longest = length;
    runStart = null;
    runEnd = null;
  }

  for (final slice in ordered) {
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
      case SliceKind.locked:
        away += slice.length;
        closeRun();
    }
  }
  closeRun();

  return DayStats(
    screenTime: screen,
    idleTime: idle,
    awayTime: away,
    longestStretch: longest,
    firstActivity: first,
    lastActivity: last,
  );
}
