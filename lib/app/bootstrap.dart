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
import '../platform/interfaces/overlay_controller.dart';
import '../platform/linux/github_update_checker.dart';
import '../platform/linux/linux_break_notifier.dart';
import '../platform/linux/linux_context_signals.dart';
import '../platform/linux/linux_idle_monitor.dart';
import '../platform/linux/linux_session_signals.dart';
import '../platform/linux/window_takeover.dart';
import '../platform/linux/xdg_autostart.dart';
import '../services/activity_recorder.dart';
import '../services/context_sampler.dart';
import '../services/engine_service.dart';
import '../services/exercise_picker.dart';
import '../services/notification_coordinator.dart';
import '../services/rollup_service.dart';
import '../services/update_service.dart';

/// Dev mode (`BREAKTIME_DEV=1 flutter run`): breaks every 1–3 minutes so
/// the full flow can be exercised without waiting real intervals.
bool get isDevMode => Platform.environment['BREAKTIME_DEV'] == '1';

const _devConfig = BreakConfig(
  microInterval: Duration(minutes: 1),
  microDuration: Duration(seconds: 10),
  longInterval: Duration(minutes: 3),
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
  OverlayController overlay,
  BreakConfig config,
  ExercisePicker picker,
  Autostart autostart,
});

/// Builds the real object graph: database, engine, Linux adapters,
/// window takeover, notification coordinator, engine service.
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

  final overlay = WindowTakeover();
  await overlay.init();

  final breakNotifier = LinuxBreakNotifier(sessionBus);
  NotificationCoordinator(engine: engine, notifier: breakNotifier).start();

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

  final service = EngineService(
    engine: engine,
    clock: clock,
    idleMonitor: LinuxIdleMonitor(sessionBus),
    sessionSignals: LinuxSessionSignals(session: sessionBus, system: systemBus),
    sampler: ContextSampler(LinuxContextSignals()),
    breakLog: breakLogRepo,
    settings: settings,
    recorder: ActivityRecorder(activityRepo.insertSlice),
  )..start();

  return (
    db: db,
    service: service,
    overlay: overlay,
    config: config,
    picker: ExercisePicker(optOuts: optOuts),
    autostart: XdgAutostart(),
  );
}
