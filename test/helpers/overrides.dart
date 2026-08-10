// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:restifeye/core/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/engine/snapshot.dart';
import 'package:restifeye/core/models/activity.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/data/activity_repository.dart';
import 'package:restifeye/data/break_log_repository.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:restifeye/platform/fake/fake_overlay.dart';
import 'package:restifeye/platform/fake/fake_signals.dart';
import 'package:restifeye/platform/interfaces/sound_player.dart';
import 'package:restifeye/services/activity_recorder.dart';
import 'package:restifeye/services/app_lifecycle.dart';
import 'package:restifeye/services/context_sampler.dart';
import 'package:restifeye/services/engine_service.dart';
import 'package:restifeye/services/exercise_picker.dart';
import 'package:restifeye/services/providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// A full app harness on fakes: real engine + in-memory DB, manual clock,
/// no D-Bus, no window manager. Drive time with [advance].
class TestHarness {
  TestHarness({
    BreakConfig config = const BreakConfig(),
    EngineSnapshot? restoreFrom,
  }) : clock = ManualClock(),
       db = AppDatabase.inMemory(),
       overlay = FakeOverlayController(),
       idle = FakeIdleMonitor(),
       session = FakeSessionSignals(),
       context = FakeContextSignals(),
       presentation = FakePresentationSignals() {
    engine = BreakEngine(
      clock: clock,
      config: config,
      restoreFrom: restoreFrom,
    );
    service = EngineService(
      engine: engine,
      clock: clock,
      idleMonitor: idle,
      sessionSignals: session,
      sampler: ContextSampler(context),
      presentation: PresentationSampler(presentation),
      breakLog: BreakLogRepository(db),
      settings: SettingsRepository(db),
      recorder: ActivityRecorder(ActivityRepository(db).insertSlice),
    );
    lifecycle = AppLifecycle(
      overlay: overlay,
      service: service,
      tray: tray,
      exitProcess: (code) => exitCode = code, // never kill the test runner
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
  final FakePresentationSignals presentation;
  final FakeTrayIndicator tray = FakeTrayIndicator();
  final SilentSoundPlayer sounds = SilentSoundPlayer();
  late final BreakEngine engine;
  late final EngineService service;
  late final AppLifecycle lifecycle;

  /// Set when the app would have exited; null while it is still running.
  int? exitCode;

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
        autostartProvider.overrideWithValue(FakeAutostart()),
        appLifecycleProvider.overrideWithValue(lifecycle),
        soundPlayerProvider.overrideWithValue(sounds),
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
