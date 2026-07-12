import 'dart:math';

import 'package:breaktime/core/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:breaktime/core/engine/engine.dart';
import 'package:breaktime/core/models/activity.dart';
import 'package:breaktime/core/models/break_config.dart';
import 'package:breaktime/data/activity_repository.dart';
import 'package:breaktime/data/break_log_repository.dart';
import 'package:breaktime/data/database.dart';
import 'package:breaktime/data/settings_repository.dart';
import 'package:breaktime/platform/fake/fake_overlay.dart';
import 'package:breaktime/platform/fake/fake_signals.dart';
import 'package:breaktime/services/activity_recorder.dart';
import 'package:breaktime/services/context_sampler.dart';
import 'package:breaktime/services/engine_service.dart';
import 'package:breaktime/services/exercise_picker.dart';
import 'package:breaktime/services/providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full app harness on fakes: real engine + in-memory DB, manual clock,
/// no D-Bus, no window manager. Drive time with [advance].
class TestHarness {
  TestHarness({BreakConfig config = const BreakConfig()})
    : clock = ManualClock(),
      db = AppDatabase.inMemory(),
      overlay = FakeOverlayController(),
      idle = FakeIdleMonitor(),
      session = FakeSessionSignals(),
      context = FakeContextSignals() {
    engine = BreakEngine(clock: clock, config: config);
    service = EngineService(
      engine: engine,
      clock: clock,
      idleMonitor: idle,
      sessionSignals: session,
      sampler: ContextSampler(context),
      breakLog: BreakLogRepository(db),
      settings: SettingsRepository(db),
      recorder: ActivityRecorder(ActivityRepository(db).insertSlice),
    );
    // Note: service is NOT started — tests tick the engine directly for
    // full determinism.
  }

  final ManualClock clock;
  final AppDatabase db;
  final FakeOverlayController overlay;
  final FakeIdleMonitor idle;
  final FakeSessionSignals session;
  final FakeContextSignals context;
  late final BreakEngine engine;
  late final EngineService service;

  /// Advances the engine in 1 s ticks.
  void advance(Duration duration, [TickInput input = const TickInput()]) {
    var remaining = duration;
    const step = Duration(seconds: 1);
    while (remaining > Duration.zero) {
      clock.advance(step);
      engine.tick(input);
      remaining -= step;
    }
  }

  /// Wraps [child] in a ProviderScope bound to this harness. The overrides
  /// list must stay an inline literal: Riverpod 3 does not export the
  /// Override type, so it can only exist as an inferred type.
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        engineServiceProvider.overrideWithValue(service),
        overlayControllerProvider.overrideWithValue(overlay),
        seedConfigProvider.overrideWithValue(engine.config),
        exercisePickerProvider.overrideWithValue(
          ExercisePicker(random: Random(7)),
        ),
        onboardingDoneProvider.overrideWith((ref) => Future.value(true)),
      ],
      child: child,
    );
  }

  Future<void> dispose() => db.close();
}

/// Unmounts the widget tree and flushes the zero-duration timers drift
/// schedules when its query streams close. MUST be awaited as the LAST
/// line of every widget test using [TestHarness], or the pending-timer
/// invariant fails.
///
/// Deliberately does NOT close the in-memory database: drift's close()
/// depends on real async and deadlocks inside the FakeAsync test zone.
/// Leaking a per-test in-memory database is harmless.
Future<void> cleanupHarness(WidgetTester tester, TestHarness harness) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Drift's stream-close chain spans several microtask/timer hops; give it
  // enough elapsed pumps to fully drain.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

/// Slice/count fixtures used by dashboard assertions.
const fixtureDayStats = DayStats(
  screenTime: Duration(hours: 3, minutes: 20),
  longestStretch: Duration(minutes: 80),
);
