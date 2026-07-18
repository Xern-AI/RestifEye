import 'dart:async';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/engine/events.dart';
import '../core/engine/phase.dart';
import '../core/mood/mood.dart';
import '../core/mood/mood_rules.dart';
import '../core/mood/mood_tracker.dart';
import '../data/activity_repository.dart';
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
    this._rules = const MoodRules(),
    MoodTracker? tracker,
  }) : _tracker = tracker ?? MoodTracker(escalateAfter: _escalateAfter);

  /// Three samples before escalating. Combined with the recompute cadence
  /// this means a worsening mood has to persist for minutes, not seconds.
  static const _escalateAfter = 3;

  /// Screen time is a database read, so it is refreshed on a slow cadence
  /// rather than on every recompute.
  static const _screenTimeEvery = Duration(minutes: 1);

  final BreakEngine _engine;
  final Clock _clock;
  final SettingsRepository _settings;
  final ActivityRepository _activity;
  final MoodRules _rules;
  final MoodTracker _tracker;

  final _moods = StreamController<Mood>.broadcast();
  final List<BreakResponse> _recent = [];

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
    _recent.addAll(await _loadRecent());

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
    _timer = Timer.periodic(_screenTimeEvery, (_) async {
      await _refreshScreenTime();
      _recompute();
    });
    _recompute();
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

    if (response == BreakResponse.honored) _lastRestAt = _clock.now();
    _recent.add(response);
    // Only the window is ever consulted, so only the window is kept — this
    // list must not grow for the lifetime of the process.
    while (_recent.length > _rules.window) {
      _recent.removeAt(0);
    }
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

  void _recompute() {
    final now = _clock.now();
    final raw = computeMood(
      MoodInputs(
        recent: List.unmodifiable(_recent),
        screenTime: _screenTime,
        // Before the first break of the session there is no "last rest" to
        // measure from, so fatigue is judged on screen time alone rather
        // than on an invented age.
        sinceLastRest: _lastRestAt == null
            ? Duration.zero
            : now.difference(_lastRestAt!),
        inBreak: _inBreak,
        paused: _paused,
      ),
      rules: _rules,
    );
    final mood = _tracker.update(raw);
    if (mood == _published) return; // only publish real changes
    _published = mood;
    if (!_moods.isClosed) _moods.add(mood);
  }

  /// The window survives a restart: a mood that resets to cheerful on every
  /// launch would mean the icon never says anything true after a reboot, and
  /// would make restarting a way to clear a warning.
  Future<List<BreakResponse>> _loadRecent() async {
    final raw = await _settings.readValue(SettingsRepository.keyMoodRecent);
    if (raw == null || raw.isEmpty) return const [];
    final byName = {for (final r in BreakResponse.values) r.name: r};
    return [for (final name in raw.split(',')) ?byName[name]];
  }

  Future<void> _saveRecent() => _settings.writeValue(
    SettingsRepository.keyMoodRecent,
    _recent.map((r) => r.name).join(','),
  );

  Future<void> dispose() async {
    _timer?.cancel();
    await _eventSub?.cancel();
    await _phaseSub?.cancel();
    await _moods.close();
  }
}
