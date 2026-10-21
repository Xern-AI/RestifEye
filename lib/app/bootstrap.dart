// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/models/break_config.dart';
import '../core/models/exercise.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';
import '../data/rollup_repository.dart';
import '../platform/desktop/window_takeover.dart';
import '../platform/interfaces/app_log.dart';
import '../platform/interfaces/autostart.dart';
import '../platform/interfaces/break_notifier.dart';
import '../platform/interfaces/sound_player.dart';
import '../platform/interfaces/tray_indicator.dart';
import '../platform/interfaces/tray_support.dart';
import '../platform/linux/linux_adapters.dart';
import '../platform/windows/windows_adapters.dart';
import '../platform/windows/windows_version.dart';
import '../services/activity_recorder.dart';
import '../services/context_sampler.dart';
import '../services/engine_service.dart';
import '../services/exercise_picker.dart';
import '../services/mood_service.dart';
import '../services/notification_coordinator.dart';
import '../services/phase_log.dart';
import '../services/rollup_service.dart';
import 'version.dart';
import '../services/update_service.dart';
import 'brand.dart';

/// Dev mode (`RESTIFEYE_DEV=1 flutter run`): breaks every 1–3 minutes so
/// the full flow can be exercised without waiting real intervals.
bool get isDevMode => Platform.environment['RESTIFEYE_DEV'] == '1';

/// Long interval must clear `micro + BreakEngine._mergeWindow` (2 min) or the
/// long break absorbs every micro one and eye breaks can never be exercised.
/// At the old 1/3 min the merge rule held on the very first cycle, so dev mode
/// silently never fired a single standalone eye break. 6 min gives five real
/// micro cycles, then one merged long break — the same shape as production.
const _devConfig = BreakConfig(
  microInterval: Duration(minutes: 1),
  microDuration: Duration(seconds: 10),
  longInterval: Duration(minutes: 6),
  longDuration: Duration(seconds: 30),
  warningLead: Duration(seconds: 10),
  snoozeLength: Duration(seconds: 20),
  idleFireThreshold: Duration(seconds: 30),
  deferRecheck: Duration(seconds: 15),
  deferCap: Duration(minutes: 1),
);

/// Everything main() needs to run the app.
/// (Riverpod 3 no longer exports the `Override` type — API change from 2.x —
/// so the overrides list is built as an inferred literal at the call site.)
typedef BootResult = ({
  AppDatabase db,
  EngineService service,
  WindowTakeover overlay,
  BreakConfig config,
  ExercisePicker picker,
  Autostart autostart,
  TrayIndicator tray,
  SoundPlayer sounds,
  TrayHostSupport traySupport,
  MoodService mood,
  bool moodIndicator,
  List<int>? traySizes,
  bool updateChecks,
});

/// Builds the real object graph: database, engine, platform adapters,
/// window takeover, notification coordinator, tray, engine service.
///
/// The adapters are the only part that differs between Linux and Windows;
/// everything built on them is shared.
Future<BootResult> bootstrap({AppLog log = const NoAppLog()}) async {
  await loadAppVersion();
  if (Platform.isWindows) {
    final version = exeProductVersion(Platform.resolvedExecutable);
    if (version != null) applyVersionString(version);
  }
  log.info(
    'startup ${Brand.appName} $appVersion (build ${appBuild ?? '?'}) '
    'on ${Platform.operatingSystemVersion}',
  );

  final db = AppDatabase.open();
  log.info('database ${AppDatabase.productionPath}');
  final settings = SettingsRepository(db);

  final config = isDevMode ? _devConfig : await settings.loadConfig();
  final snapshot = isDevMode ? null : await settings.loadSnapshot();
  final optOuts = await settings.loadExerciseOptOuts();
  final maxIntensityName = await settings.readValue(
    SettingsRepository.keyMaxIntensity,
  );

  final clock = SystemClock();
  final engine = BreakEngine(
    clock: clock,
    config: config,
    restoreFrom: snapshot,
  );

  final soundsEnabled = await settings.getFlag(
    SettingsRepository.flagSounds,
    fallback: true,
  );
  final platform = Platform.isWindows
      ? await windowsAdapters(soundsEnabled: soundsEnabled, log: log)
      : linuxAdapters(soundsEnabled: soundsEnabled);
  final activityRepo = ActivityRepository(db);
  final breakLogRepo = BreakLogRepository(db);

  final breakNotifier = platform.notifier;
  final sounds = platform.sounds;
  // Declared late so the notification's "Return to break" action can reach
  // the window takeover, which is built below.
  late final WindowTakeover overlay;
  NotificationCoordinator(
    engine: engine,
    notifier: breakNotifier,
    sounds: sounds,
    onReturnToBreak: () => unawaited(overlay.presentWindow()),
  ).start();

  final traySupport = platform.traySupport;

  // Closing to the background gets a "still running" notice so nobody thinks
  // the app quit.
  overlay = WindowTakeover(
    ops: platform.windowOps,
    onHiddenToBackground: () => unawaited(
      _maybeShowHideNotice(
        settings,
        breakNotifier,
        traySupport,
      ).catchError((Object _) {}),
    ),
  );
  await overlay.init();
  platform.relaunches.listen((_) => unawaited(overlay.presentWindow()));

  // Launch at login is the default: a break reminder that only runs when
  // you remember to start it churns users. One-time so an explicit opt-out
  // in Settings is never overridden on the next start.
  final autostart = platform.autostart;
  if (!isDevMode) {
    final applied = await settings.getFlag(
      SettingsRepository.flagAutostartApplied,
      fallback: false,
    );
    if (!applied) {
      try {
        await autostart.setEnabled(true);
      } on Exception catch (e) {
        // Read-only config dir, or a registry write Windows refused — the
        // Settings toggle stays available.
        log.failure('autostart', e);
      }
      await settings.setFlag(SettingsRepository.flagAutostartApplied, true);
    }
  }

  RollupService(
    activity: activityRepo,
    breakLog: breakLogRepo,
    rollups: RollupRepository(db),
    clock: clock,
  ).start();

  final updateChecker = platform.updateChecker;
  if (updateChecker != null) {
    unawaited(
      UpdateService(
        checker: updateChecker,
        notifier: breakNotifier,
        settings: settings,
        clock: clock,
      ).maybeCheck().catchError((Object _) => null),
    );
  }

  final service =
      EngineService(
          engine: engine,
          clock: clock,
          idleMonitor: platform.idle,
          sessionSignals: platform.session,
          sampler: ContextSampler(platform.context),
          presentation: PresentationSampler(platform.presentation),
          overlay: overlay,
          breakLog: breakLogRepo,
          settings: settings,
          recorder: ActivityRecorder(activityRepo.insertSlice),
        )
        ..pauseDuringMedia = await settings.getFlag(
          SettingsRepository.flagPauseDuringMedia,
          fallback: true,
        )
        ..start();

  final mood = MoodService(
    engine: engine,
    clock: clock,
    settings: settings,
    activity: activityRepo,
    breaks: breakLogRepo,
  );
  await mood.start();
  if (log.enabled) PhaseLog(engine: engine, log: log).start();

  return (
    db: db,
    service: service,
    overlay: overlay,
    config: config,
    picker: ExercisePicker(
      optOuts: optOuts,
      maxIntensity: ExerciseIntensity.values.firstWhere(
        (v) => v.name == maxIntensityName,
        orElse: () => ExerciseIntensity.medium,
      ),
    ),
    autostart: autostart,
    tray: platform.tray,
    sounds: sounds,
    traySupport: traySupport,
    mood: mood,
    moodIndicator: await settings.getFlag(
      SettingsRepository.flagMoodIndicator,
      fallback: true,
    ),
    traySizes: platform.traySizes,
    updateChecks: updateChecker != null,
  );
}

/// Tells the user the app is still alive after they close the window.
///
/// Shown once when a tray icon exists to point at. When it does not — GNOME
/// without the AppIndicator extension — the window has just vanished with no
/// visible way back, so the notice repeats every time and says how to return.
/// Being mildly repetitive beats leaving someone unable to reach the app.
Future<void> _maybeShowHideNotice(
  SettingsRepository settings,
  BreakNotifier notifier,
  TrayHostSupport traySupport,
) async {
  final tray = await traySupport.check();
  final hasTray = tray.state == TrayState.working;

  if (hasTray) {
    final shown = await settings.getFlag(
      SettingsRepository.flagHideNoticeShown,
      fallback: false,
    );
    if (shown) return;
    await settings.setFlag(SettingsRepository.flagHideNoticeShown, true);
  }

  await notifier.showInfo(
    title: '${Brand.appName} is still running',
    body: hasTray
        ? 'Breaks continue in the background. Reopen it from the tray icon.'
        : 'Breaks continue in the background. There is no tray icon yet — '
              'launch ${Brand.appName} again to reopen this window, or turn '
              'the tray on in Settings.',
  );
}
