import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/models/break_config.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';
import '../data/rollup_repository.dart';
import '../platform/interfaces/autostart.dart';
import '../platform/interfaces/sound_player.dart';
import '../platform/interfaces/tray_indicator.dart';
import '../platform/interfaces/tray_support.dart';
import '../platform/linux/github_update_checker.dart';
import '../platform/linux/gnome_tray_support.dart';
import '../platform/linux/linux_break_notifier.dart';
import '../platform/linux/linux_context_signals.dart';
import '../platform/linux/linux_idle_monitor.dart';
import '../platform/linux/linux_presentation_signals.dart';
import '../platform/linux/linux_session_signals.dart';
import '../platform/linux/linux_sound_player.dart';
import '../platform/linux/sni_tray.dart';
import '../platform/linux/window_takeover.dart';
import '../platform/linux/xdg_autostart.dart';
import '../services/activity_recorder.dart';
import '../services/context_sampler.dart';
import '../services/engine_service.dart';
import '../services/exercise_picker.dart';
import '../services/mood_service.dart';
import '../services/notification_coordinator.dart';
import '../services/rollup_service.dart';
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
});

/// Builds the real object graph: database, engine, Linux adapters,
/// window takeover, notification coordinator, tray, engine service.
Future<BootResult> bootstrap() async {
  final db = AppDatabase.open();
  final settings = SettingsRepository(db);

  final config = isDevMode ? _devConfig : await settings.loadConfig();
  final snapshot = isDevMode ? null : await settings.loadSnapshot();
  final optOuts = await settings.loadExerciseOptOuts();

  final clock = SystemClock();
  final engine = BreakEngine(
    clock: clock,
    config: config,
    restoreFrom: snapshot,
  );

  final sessionBus = DBusClient.session();
  final systemBus = DBusClient.system();
  final activityRepo = ActivityRepository(db);
  final breakLogRepo = BreakLogRepository(db);

  final breakNotifier = LinuxBreakNotifier(sessionBus);
  final sounds = LinuxSoundPlayer(
    enabled: await settings.getFlag(
      SettingsRepository.flagSounds,
      fallback: true,
    ),
  );
  NotificationCoordinator(
    engine: engine,
    notifier: breakNotifier,
    sounds: sounds,
  ).start();

  final traySupport = GnomeTraySupport(sessionBus);

  // Closing to the background gets a "still running" notice so nobody thinks
  // the app quit.
  final overlay = WindowTakeover(
    onHiddenToBackground: () =>
        unawaited(_maybeShowHideNotice(settings, breakNotifier, traySupport)),
  );
  await overlay.init();

  // Launch at login is the default: a break reminder that only runs when
  // you remember to start it churns users. One-time so an explicit opt-out
  // in Settings is never overridden on the next start.
  final autostart = XdgAutostart();
  if (!isDevMode) {
    final applied = await settings.getFlag(
      SettingsRepository.flagAutostartApplied,
      fallback: false,
    );
    if (!applied) {
      try {
        await autostart.setEnabled(true);
      } on FileSystemException {
        // Read-only config dir — the Settings toggle stays available.
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

  unawaited(
    UpdateService(
      checker: GithubUpdateChecker(),
      notifier: breakNotifier,
      settings: settings,
      clock: clock,
    ).maybeCheck(),
  );

  final service =
      EngineService(
          engine: engine,
          clock: clock,
          idleMonitor: LinuxIdleMonitor(sessionBus),
          sessionSignals: LinuxSessionSignals(
            session: sessionBus,
            system: systemBus,
          ),
          sampler: ContextSampler(LinuxContextSignals()),
          presentation: PresentationSampler(
            LinuxPresentationSignals(session: sessionBus, system: systemBus),
          ),
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
  );
  await mood.start();

  return (
    db: db,
    service: service,
    overlay: overlay,
    config: config,
    picker: ExercisePicker(optOuts: optOuts),
    autostart: autostart,
    tray: SniTrayIndicator(sessionBus),
    sounds: sounds,
    traySupport: traySupport,
    mood: mood,
    moodIndicator: await settings.getFlag(
      SettingsRepository.flagMoodIndicator,
      fallback: true,
    ),
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
  LinuxBreakNotifier notifier,
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
