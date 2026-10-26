// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../../app/platform_adapters.dart';
import '../interfaces/app_log.dart';
import '../interfaces/autostart.dart';
import 'user_registry.dart';
import 'windows_autostart.dart';
import 'windows_break_notifier.dart';
import 'windows_context_signals.dart';
import 'windows_idle_monitor.dart';
import 'windows_licence_store.dart';
import 'windows_presentation_signals.dart';
import 'windows_runner.dart';
import 'windows_session_signals.dart';
import 'windows_sound_player.dart';
import 'windows_startup_task.dart';
import 'windows_tray.dart';
import 'windows_tray_support.dart';
import 'windows_window_ops.dart';

/// The Windows adapters. Each one is exercised once here so the log says
/// plainly which started and which did not; a failure is logged and the app
/// carries on, exactly as the adapters themselves fail open at runtime.
///
/// There is no update checker: there are no public Windows releases to
/// compare against, and the Store will deliver updates.
Future<PlatformAdapters> windowsAdapters({
  required bool soundsEnabled,
  required AppLog log,
}) async {
  Future<void> check(String name, FutureOr<void> Function() probe) async {
    try {
      await probe();
      log.info('adapter $name ok');
    } on Object catch (e) {
      log.failure(name, e);
    }
  }

  const registry = Win32UserRegistry();
  final runner = WindowsRunner();
  await check('runner', runner.ping);

  final idle = WindowsIdleMonitor(log: log);
  await check('idle', idle.probe);

  final session = WindowsSessionSignals(runner, log: log);
  await check('session', () async {
    if (!await runner.startSessionEvents()) {
      throw StateError('WTSRegisterSessionNotification refused');
    }
  });

  final context = WindowsContextSignals(registry: registry, log: log);
  await check('meeting', context.probe);

  final presentation = WindowsPresentationSignals(log: log);
  await check('presentation', presentation.probe);

  var packaged = false;
  await check('package', () async => packaged = await runner.isPackaged());
  log.info(packaged ? 'Store build' : 'test build (not from the Store)');

  final notifier = WindowsBreakNotifier(
    backend: PluginToastBackend(),
    log: log,
    singleRemoval: packaged,
  );
  await check('notifications', notifier.start);

  final Autostart autostart;
  if (packaged) {
    final task = WindowsStartupTask(runner);
    autostart = task;
    await check('autostart', task.isEnabled);
  } else {
    final runKey = WindowsAutostart(
      registry: registry,
      executable: Platform.resolvedExecutable,
    );
    autostart = runKey;
    await check('autostart', () async {
      if (await runKey.repairPath()) {
        log.info('autostart now points at ${Platform.resolvedExecutable}');
      }
    });
  }

  final sounds = WindowsSoundPlayer(log: log, enabled: soundsEnabled);
  log.info('adapter sound ok');
  log.info('update check off on Windows');

  return (
    notifier: notifier,
    sounds: sounds,
    traySupport: const WindowsTraySupport(),
    windowOps: WindowsWindowOps(runner, log),
    autostart: autostart,
    updateChecker: null,
    idle: idle,
    session: session,
    context: context,
    presentation: presentation,
    tray: WindowsTrayIndicator(runner: runner, log: log),
    licenceStore: WindowsLicenceStore(runner, isStoreBuild: packaged),
    traySizes: windowsTraySizes,
    relaunches: runner.relaunches,
  );
}
