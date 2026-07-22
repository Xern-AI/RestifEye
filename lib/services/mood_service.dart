import 'dart:async';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/engine/events.dart';
import '../core/engine/phase.dart';
import '../core/mood/mood.dart';
import '../core/mood/mood_rules.dart';
import '../core/mood/mood_tracker.dart';
import '../core/mood/mood_window.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/settings_repository.dart';

/// Works out how the app should feel about the user's day, and publishes it.
///
/// Deliberately knows nothing about icons or D-Bus — it produces a [Mood] and
/// stops there, so the rules can be tested without a tray, a compositor, or a
/// rendering pipeline.
class MoodService {
  MoodService({
    required this._engine,
    required this._clock,
    required this._settings,
    required this._activity,
    required this._breaks,
    this._rules = const MoodRules(),
    MoodTracker? tracker,
  }) : _tracker = tracker ?? MoodTracker(escalateAfter: _escalateAfter);

  /// Three samples before escalating. Combined with the recompute cadence
  /// this means a worsening mood has to persist for minutes, not seconds.
  static const _escalateAfter = 3;

  /// The heartbeat. Screen time is a database read, so it is refreshed on a
  /// slow cadence rather than on every recompute — and since responses now
  /// expire out of the window with nothing but time passing, this is also
  /// what lets a mood clear itself when the user simply stops misbehaving.
  static const _recomputeEvery = Duration(minutes: 1);

  final BreakEngine _engine;
  final Clock _clock;
  final SettingsRepository _settings;
  final ActivityRepository _activity;
  final BreakLogRepository _breaks;
  final MoodRules _rules;
  final MoodTracker _tracker;

  final _moods = StreamController<Mood>.broadcast();

  /// Replaced once at [start] by whatever survived from the last session.
  MoodWindow _window = MoodWindow();

  StreamSubscription<EngineEvent>? _eventSub;
  StreamSubscription<EnginePhase>? _phaseSub;
  Timer? _timer;

  DateTime? _lastRestAt;
  Duration _screenTime = Duration.zero;
  bool _inBreak = false;
  bool _paused = false;
  Mood? _published;

  Stream<Mood> get moods => _moods.stream;
  Mood get current => _tracker.current;

  Future<void> start() async {
    _window = MoodWindow.decode(
      await _settings.readValue(SettingsRepository.keyMoodRecent),
      now: _clock.now(),
      size: _rules.window,
    );
    _lastRestAt = await _lastRest();

    _eventSub = _engine.events.listen(_onEvent);

    // The phase stream ticks at 1 Hz; only genuine transitions matter, or the
    // mood would be recomputed sixty times a minute to no purpose.
    _phaseSub = _engine.phases.listen((phase) {
      final inBreak = phase is InBreak;
      final paused = phase is Paused;
      if (inBreak == _inBreak && paused == _paused) return;
      _inBreak = inBreak;
      _paused = paused;
      _recompute();
    });

    await _refreshScreenTime();
    _timer = Timer.periodic(_recomputeEvery, (_) async {
      await _refreshScreenTime();
      _recompute();
    });

    // Start from what the restored history actually says instead of
    // escalating into it over the next few minutes.
    _tracker.settle(_rawMood());
    _recompute();
  }

  /// The last completed or credited break on record, or null if there has
  /// never been one. Read from the log rather than kept in memory, so a
  /// restart cannot claim the user has just rested.
  Future<DateTime?> _lastRest() async {
    try {
      return await _breaks.lastRestAt();
    } on Object {
      return null; // no history is not an emergency; it is just no opinion
    }
  }

  void _onEvent(EngineEvent event) {
    final response = switch (event) {
      BreakCompleted() || BreakCredited() => BreakResponse.honored,
      BreakSnoozed() => BreakResponse.snoozed,
      BreakSkipped() => BreakResponse.skipped,
      BreakEscaped() => BreakResponse.escaped,
      _ => null,
    };
    if (response == null) return;

    final now = _clock.now();
    if (response == BreakResponse.honored) _lastRestAt = now;
    _window.record(response, now);
    unawaited(_saveRecent());
    _recompute();
  }

  Future<void> _refreshScreenTime() async {
    try {
      final stats = await _activity.sliceStatsFor(_clock.now());
      _screenTime = stats.screenTime;
    } on Object {
      // A stats failure must never take the tray icon down with it.
    }
  }

  /// What the rules say right now, before hysteresis.
  Mood _rawMood() {
    final now = _clock.now();
    return computeMood(
      MoodInputs(
        recent: _window.responsesAt(now),
        screenTime: _screenTime,
        // With no rest on record there is nothing to measure from, and an
        // invented age would be a judgement made up out of nothing.
        sinceLastRest: _lastRestAt == null
            ? Duration.zero
            : now.difference(_lastRestAt!),
        inBreak: _inBreak,
        paused: _paused,
      ),
      rules: _rules,
    );
  }

  void _recompute() {
    final mood = _tracker.update(_rawMood());
    if (mood == _published) return; // only publish real changes
    _published = mood;
    if (!_moods.isClosed) _moods.add(mood);
  }

  /// The window survives a restart: a mood that resets to cheerful on every
  /// launch would mean the icon never says anything true after a reboot, and
  /// would make restarting a way to clear a warning. Responses carry their
  /// timestamps, so what survives is only what is still recent.
  Future<void> _saveRecent() =>
      _settings.writeValue(SettingsRepository.keyMoodRecent, _window.encode());

  Future<void> dispose() async {
    _timer?.cancel();
    await _eventSub?.cancel();
    await _phaseSub?.cancel();
    await _moods.close();
  }
}
