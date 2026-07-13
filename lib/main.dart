import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/tray_icons.dart';
import 'platform/interfaces/tray_indicator.dart';
import 'services/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boot = await bootstrap();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(boot.db),
      engineServiceProvider.overrideWithValue(boot.service),
      overlayControllerProvider.overrideWithValue(boot.overlay),
      seedConfigProvider.overrideWithValue(boot.config),
      exercisePickerProvider.overrideWithValue(boot.picker),
      autostartProvider.overrideWithValue(boot.autostart),
    ],
  );

  unawaited(_wireTray(boot, container));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BreakTimeApp(),
    ),
  );
}

/// Tray icon: the visible "BreakTime is running" signal. Failures must
/// never take the app down — the tray is a convenience, not a dependency.
Future<void> _wireTray(BootResult boot, ProviderContainer container) async {
  try {
    await boot.tray.init(icons: await loadTrayPixmaps());
  } on Exception {
    return; // no status area / no bus — the app works without it
  }

  boot.tray.actions.listen((action) async {
    switch (action) {
      case TrayAction.open:
        await boot.overlay.presentWindow();
      case TrayAction.togglePause:
        final paused = container.read(pausedProvider);
        container.read(pausedProvider.notifier).set(!paused);
      case TrayAction.quit:
        await boot.tray.dispose();
        await boot.service.dispose();
        await boot.overlay.destroyWindow();
        exit(0);
    }
  });

  container.listen<bool>(
    pausedProvider,
    (_, paused) => unawaited(boot.tray.setPaused(paused)),
  );
}
