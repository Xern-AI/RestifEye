/// Time abstraction for the break engine.
///
/// Interval math uses [elapsed] (monotonic — immune to NTP jumps, timezone
/// changes, and manual clock edits). Wall-clock [now] is only for work-hours
/// checks, persistence timestamps, and display.
abstract interface class Clock {
  Duration elapsed();
  DateTime now();
}

class SystemClock implements Clock {
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  Duration elapsed() => _stopwatch.elapsed;

  @override
  DateTime now() => DateTime.now();
}

/// Deterministic clock for tests and dev mode.
class ManualClock implements Clock {
  ManualClock({DateTime? startAt}) : _now = startAt ?? DateTime(2026, 1, 5, 9);

  Duration _elapsed = Duration.zero;
  DateTime _now;

  void advance(Duration d) {
    _elapsed += d;
    _now = _now.add(d);
  }

  /// Jumps the wall clock without advancing monotonic time (simulates the
  /// user changing the system clock — interval math must not be affected).
  void jumpWallClock(Duration d) => _now = _now.add(d);

  @override
  Duration elapsed() => _elapsed;

  @override
  DateTime now() => _now;
}
