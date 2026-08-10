// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/tray_face.dart';
import 'core/mood/mood.dart';
import 'platform/interfaces/tray_indicator.dart';
import 'services/app_lifecycle.dart';
import 'services/providers.dart';
import 'services/tray_mood_presenter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boot = await bootstrap();

  final lifecycle = AppLifecycle(
    overlay: boot.overlay,
    service: boot.service,
    tray: boot.tray,
    mood: boot.mood,
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(boot.db),
      engineServiceProvider.overrideWithValue(boot.service),
      overlayControllerProvider.overrideWithValue(boot.overlay),
      seedConfigProvider.overrideWithValue(boot.config),
      exercisePickerProvider.overrideWithValue(boot.picker),
      autostartProvider.overrideWithValue(boot.autostart),
      appLifecycleProvider.overrideWithValue(lifecycle),
      soundPlayerProvider.overrideWithValue(boot.sounds),
      trayHostSupportProvider.overrideWithValue(boot.traySupport),
    ],
  );

  unawaited(_wireTray(boot, container, lifecycle));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RestifEyeApp(),
    ),
  );
}

/// Tray icon: the visible "RestifEye is running" signal. Failures must
/// never take the app down — the tray is a convenience, not a dependency.
Future<void> _wireTray(
  BootResult boot,
  ProviderContainer container,
  AppLifecycle lifecycle,
) async {
  // The very first icon already honours the setting: with the indicator off
  // the tray shows the neutral brand face, never a mood the user asked not
  // to see.
  final initial = boot.moodIndicator ? boot.mood.current : Mood.good;
  try {
    await boot.tray.init(icons: await renderTrayFace(initial));
  } on Exception {
    return; // no status area / no bus — the app works without it
  }

  // The face only starts moving once there is a tray to draw it on.
  final presenter = TrayMoodPresenter(
    tray: boot.tray,
    moods: boot.mood.moods,
    enabled: boot.moodIndicator,
    initial: boot.mood.current,
  );
  container.read(trayMoodPresenterProvider).presenter = presenter;
  await presenter.start();
  // Dev builds cycle the moods so the tray effects can be seen at all.
  if (isDevMode) presenter.startDemo();

  boot.tray.actions.listen((action) async {
    switch (action) {
      case TrayAction.open:
        await boot.overlay.presentWindow();
      case TrayAction.togglePause:
        final notifier = container.read(pausedProvider.notifier);
        // The tray's single item stays a plain toggle; the timed presets live
        // on the Dashboard, where the countdown is visible.
        if (container.read(pausedProvider).paused) {
          notifier.resume();
        } else {
          notifier.pause(PauseDuration.oneHour);
        }
      case TrayAction.quit:
        await lifecycle.quit();
    }
  });

  container.listen<PauseState>(
    pausedProvider,
    (_, next) => unawaited(boot.tray.setPaused(next.paused)),
  );
}
