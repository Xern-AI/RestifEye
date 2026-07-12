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
    this.longestStretch = Duration.zero,
    this.breaksCompleted = 0,
    this.breaksCredited = 0,
    this.breaksEscaped = 0,
    this.snoozes = 0,
  });

  final Duration screenTime;
  final Duration longestStretch;
  final int breaksCompleted;
  final int breaksCredited;
  final int breaksEscaped;
  final int snoozes;

  /// Fraction of concluded breaks actually rested (completed or credited).
  double get compliance {
    final total = breaksCompleted + breaksCredited + breaksEscaped;
    return total == 0 ? 1.0 : (breaksCompleted + breaksCredited) / total;
  }
}

/// Screen time and longest stretch from a day's slices.
/// Slices are assumed non-overlapping; order does not matter.
DayStats computeSliceStats(Iterable<ActivitySlice> slices) {
  var screen = Duration.zero;
  var longest = Duration.zero;
  for (final slice in slices) {
    if (slice.kind == SliceKind.active) {
      screen += slice.length;
      if (slice.length > longest) longest = slice.length;
    }
  }
  return DayStats(screenTime: screen, longestStretch: longest);
}
