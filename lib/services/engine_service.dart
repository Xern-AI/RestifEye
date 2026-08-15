// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/engine/phase.dart';
import '../core/models/activity.dart';
import '../data/break_log_repository.dart';
import '../data/settings_repository.dart';
import '../platform/interfaces/idle_monitor.dart';
import '../platform/interfaces/presentation_signals.dart';
import '../platform/interfaces/session_signals.dart';
import 'activity_recorder.dart';
import 'context_sampler.dart';

/// Drives the [BreakEngine] with real platform signals once per second and
/// fans engine output into persistence. Owns the only periodic timer in
/// the app.
class EngineService {
  EngineService({
    required this.engine,
    required this._clock,
    required this._idleMonitor,
    required this._sessionSignals,
    required this._sampler,
    required this._presentation,
    required this._breakLog,
    required this._settings,
    required this._recorder,
  });

  /// Whether the media pause is honored. Toggled from Settings; read on
  /// every tick so a change takes effect without restarting the engine.
  bool pauseDuringMedia = true;

  /// How close a break must be before busy-probing is worth its cost.
  static const _busyRelevanceWindow = Duration(seconds: 90);
  static const _flushEvery = Duration(minutes: 1);
  static const _snapshotEvery = Duration(seconds: 30);

  final BreakEngine engine;
  final Clock _clock;
  final IdleMonitor _idleMonitor;
  final SessionSignals _sessionSignals;
  final ContextSampler _sampler;
  final PresentationSampler _presentation;
  final BreakLogRepository _breakLog;
  final SettingsRepository _settings;
  final ActivityRecorder _recorder;

  Timer? _timer;
  StreamSubscription<bool>? _awaySub;
  StreamSubscription<Object?>? _eventSub;
  bool _away = false;
  DateTime _lastFlush = DateTime.now();
  DateTime _lastSnapshot = DateTime.now();
  bool _ticking = false;

  void start({Duration tickEvery = const Duration(seconds: 1)}) {
    _awaySub = _sessionSignals.away.listen((away) => _away = away);
    _eventSub = engine.events.listen((event) {
      // Fire-and-forget: persistence must never block the engine.
      unawaited(_breakLog.record(event));
      unawaited(_settings.saveSnapshot(engine.snapshot()));
    });
    _timer = Timer.periodic(tickEvery, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_ticking) return; // a slow D-Bus reply must not stack ticks
    _ticking = true;
    try {
      final idle = await _idleMonitor.currentIdle();
      final phase = engine.phase;
      final relevant = switch (phase) {
        Monitoring(:final nextBreakIn) => nextBreakIn < _busyRelevanceWindow,
        Warning() || Deferred() => true,
        InBreak() || Paused() => false,
      };
      final now = _clock.now();
      await _sampler.refreshIfNeeded(relevant: relevant, now: now);
      // Sampled whether or not the pause is wanted: the setting decides
      // whether a film delays a break, not whether watch time is counted.
      await _presentation.refresh(now);
      final presenting = pauseDuringMedia
          ? _presentation.value
          : PresentationState.idle;

      engine.tick(
        TickInput(
          idle: idle,
          locked: _away,
          busy: _sampler.value,
          presenting: presenting.active,
          presentingApp: presenting.byApp,
        ),
      );

      _recorder.observe(
        now,
        classifySlice(
          away: _away,
          idle: idle,
          idleThreshold: engine.config.idleFireThreshold,
          presenting: _presentation.value.active,
        ),
      );
      if (now.difference(_lastFlush) >= _flushEvery) {
        _lastFlush = now;
        await _recorder.flush(now);
      }
      if (now.difference(_lastSnapshot) >= _snapshotEvery) {
        _lastSnapshot = now;
        await _settings.saveSnapshot(engine.snapshot());
      }
    } finally {
      _ticking = false;
    }
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _awaySub?.cancel();
    await _eventSub?.cancel();
    await _recorder.flush(_clock.now());
    await _settings.saveSnapshot(engine.snapshot());
    engine.dispose();
  }
}
