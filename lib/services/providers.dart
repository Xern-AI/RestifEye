import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../core/models/activity.dart';
import '../core/models/break_config.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/database.dart';
import '../data/exercise_log_repository.dart';
import '../data/rollup_repository.dart';
import '../data/settings_repository.dart';
import '../platform/interfaces/autostart.dart';
import '../platform/interfaces/overlay_controller.dart';
import '../platform/interfaces/sound_player.dart';
import '../platform/interfaces/tray_support.dart';
import 'advice_engine.dart';
import 'app_lifecycle.dart';
import 'engine_service.dart';
import 'tray_mood_presenter.dart';
import 'exercise_picker.dart';

/// Concrete instances are created in the bootstrap (or in tests) and
/// injected via ProviderScope overrides — providers here only declare
/// the graph's shape.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final engineServiceProvider = Provider<EngineService>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final overlayControllerProvider = Provider<OverlayController>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

/// Quit, shared by the tray menu and the Ctrl+Q shortcut.
final appLifecycleProvider = Provider<AppLifecycle>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

/// The config as loaded at startup (seed for [breakConfigProvider]).
final seedConfigProvider = Provider<BreakConfig>((ref) => const BreakConfig());

/// Editable break configuration; updates flow to the engine and disk.
final breakConfigProvider = NotifierProvider<ConfigNotifier, BreakConfig>(
  ConfigNotifier.new,
);

class ConfigNotifier extends Notifier<BreakConfig> {
  @override
  BreakConfig build() => ref.watch(seedConfigProvider);

  Future<void> update(BreakConfig config) async {
    state = config;
    ref.read(engineServiceProvider).engine.updateConfig(config);
    await ref.read(settingsRepositoryProvider).saveConfig(config);
  }
}

final exercisePickerProvider = Provider<ExercisePicker>(
  (ref) => ExercisePicker(),
);

/// First-run gate; false shows onboarding.
final onboardingDoneProvider = FutureProvider<bool>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .getFlag(SettingsRepository.flagOnboardingDone, fallback: false),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(databaseProvider)),
);

final breakLogRepositoryProvider = Provider<BreakLogRepository>(
  (ref) => BreakLogRepository(ref.watch(databaseProvider)),
);

final exerciseLogRepositoryProvider = Provider<ExerciseLogRepository>(
  (ref) => ExerciseLogRepository(ref.watch(databaseProvider)),
);

/// Live engine phase for the dashboard countdown and overlay triggers.
final enginePhaseProvider = StreamProvider<EnginePhase>(
  (ref) => ref.watch(engineServiceProvider).engine.phases,
);

/// Wall-clock source for date-sensitive providers; overridden in tests.
final wallClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current local calendar day (midnight-truncated).
///
/// Capturing `DateTime.now()` inside a long-lived provider pins it to the
/// day the provider was first read: an app left running froze the dashboard
/// on its launch day forever. This provider invalidates itself when the
/// local date changes, so everything derived from "today" rolls over at
/// midnight. A short periodic re-check is used rather than one timer aimed
/// at midnight because monotonic timers stop during suspend and would fire
/// hours late after resume.
final todayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(wallClockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    final n = ref.read(wallClockProvider)();
    if (DateTime(n.year, n.month, n.day) != today) ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  return today;
});

/// Today's screen time / longest stretch, reactive to new slices.
final todaySliceStatsProvider = StreamProvider<DayStats>(
  (ref) => ref
      .watch(activityRepositoryProvider)
      .watchSliceStats(ref.watch(todayProvider)),
);

/// Today's break outcome counts, reactive to new break events.
final todayBreakCountsProvider = StreamProvider<BreakCounts>(
  (ref) => ref
      .watch(breakLogRepositoryProvider)
      .watchDayCounts(ref.watch(todayProvider)),
);

final autostartProvider = Provider<Autostart>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final rollupRepositoryProvider = Provider<RollupRepository>(
  (ref) => RollupRepository(ref.watch(databaseProvider)),
);

/// Which analytics range is selected.
enum AnalyticsRange { week, month, year }

final analyticsRangeProvider =
    NotifierProvider<AnalyticsRangeNotifier, AnalyticsRange>(
      AnalyticsRangeNotifier.new,
    );

class AnalyticsRangeNotifier extends Notifier<AnalyticsRange> {
  @override
  AnalyticsRange build() => AnalyticsRange.week;

  void select(AnalyticsRange range) => state = range;
}

/// Rollups covering the selected analytics range (finished days only —
/// today is shown live on the dashboard instead).
final rangeRollupsProvider = StreamProvider<List<DayRollup>>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  final today = ref.watch(todayProvider);
  final from = switch (range) {
    AnalyticsRange.week => today.subtract(const Duration(days: 7)),
    AnalyticsRange.month => today.subtract(const Duration(days: 30)),
    AnalyticsRange.year => DateTime(today.year - 1, today.month, today.day),
  };
  return ref.watch(rollupRepositoryProvider).watchRange(from, today);
});

/// Current advice from the last four weeks of rollups.
final adviceProvider = StreamProvider<List<Advice>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(rollupRepositoryProvider)
      .watchRange(today.subtract(const Duration(days: 28)), today)
      .map(evaluateAdvice);
});

/// How long a pause lasts. Open-ended is available but never the default:
/// a break reminder silenced "for now" and then forgotten is a break reminder
/// that has stopped working, and the user will never notice.
enum PauseDuration {
  thirtyMinutes(Duration(minutes: 30), '30 minutes'),
  oneHour(Duration(hours: 1), '1 hour'),
  twoHours(Duration(hours: 2), '2 hours'),
  threeHours(Duration(hours: 3), '3 hours'),
  indefinite(null, 'Until I resume');

  const PauseDuration(this.length, this.label);

  final Duration? length;
  final String label;
}

/// Paused state, with the wall-clock deadline of a timed pause.
typedef PauseState = ({bool paused, DateTime? until});

const _notPaused = (paused: false, until: null);

/// Engine pause, mirrored for the UI and persisted across restarts.
final pausedProvider = NotifierProvider<PausedNotifier, PauseState>(
  PausedNotifier.new,
);

class PausedNotifier extends Notifier<PauseState> {
  static const _key = 'paused_until';

  @override
  PauseState build() {
    // Restore an in-flight timed pause; the engine ticks it down from here.
    unawaited(_restore());
    return _notPaused;
  }

  Future<void> _restore() async {
    final raw = await ref.read(settingsRepositoryProvider).readValue(_key);
    if (raw == null) return;
    final until = DateTime.tryParse(raw);
    // A lapsed deadline means the pause expired while the app was closed.
    if (until == null || !until.isAfter(DateTime.now())) {
      await _clear();
      return;
    }
    _apply((paused: true, until: until));
  }

  /// [duration] null means open-ended.
  void pause(PauseDuration duration) {
    final length = duration.length;
    _apply((
      paused: true,
      until: length == null ? null : DateTime.now().add(length),
    ));
    unawaited(_persist());
  }

  void resume() {
    _apply(_notPaused);
    unawaited(_clear());
  }

  /// Reflects a pause that lapsed inside the engine (auto-resume).
  void syncFromEngine(PauseState engineState) {
    if (engineState.paused == state.paused) return;
    state = engineState;
    if (!engineState.paused) unawaited(_clear());
  }

  void _apply(PauseState next) {
    state = next;
    ref
        .read(engineServiceProvider)
        .engine
        .setPausedByUser(next.paused, until: next.until);
  }

  Future<void> _persist() async {
    final until = state.until;
    final settings = ref.read(settingsRepositoryProvider);
    // An open-ended pause is intentionally not persisted as a deadline; the
    // engine simply starts unpaused next launch rather than silently staying
    // dead forever.
    await settings.writeValue(_key, until?.toIso8601String() ?? '');
  }

  Future<void> _clear() =>
      ref.read(settingsRepositoryProvider).writeValue(_key, '');
}

/// Sound output, injected so tests stay silent.
final soundPlayerProvider = Provider<SoundPlayer>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final trayHostSupportProvider = Provider<TrayHostSupport>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

/// Whether the tray icon can actually be drawn, and what to do if it cannot.
/// Refreshed by [TrayStatusNotifier.recheck] after the user acts.
final trayStatusProvider =
    AsyncNotifierProvider<TrayStatusNotifier, TraySupport>(
      TrayStatusNotifier.new,
    );

class TrayStatusNotifier extends AsyncNotifier<TraySupport> {
  @override
  Future<TraySupport> build() => ref.watch(trayHostSupportProvider).check();

  /// Turns the required shell extension on. Only ever from an explicit click:
  /// silently changing a user's shell configuration would be out of order.
  Future<void> enable() async {
    state = const AsyncLoading<TraySupport>();
    state = await AsyncValue.guard(
      () => ref.read(trayHostSupportProvider).enable(),
    );
  }

  Future<void> recheck() async {
    state = await AsyncValue.guard(
      () => ref.read(trayHostSupportProvider).check(),
    );
  }
}

/// Autostart, update-check, break-window and sound switches (persisted).
class GeneralSettings {
  const GeneralSettings({
    required this.autostart,
    required this.updateCheck,
    required this.fullscreenOverlay,
    required this.sounds,
    required this.pauseDuringMedia,
    required this.moodIndicator,
  });

  final bool autostart;
  final bool updateCheck;
  final bool fullscreenOverlay;
  final bool sounds;

  /// Hold breaks while a fullscreen video or presentation is running.
  final bool pauseDuringMedia;

  /// Let the tray icon's expression reflect how the day is going.
  final bool moodIndicator;

  GeneralSettings copyWith({
    bool? autostart,
    bool? updateCheck,
    bool? fullscreenOverlay,
    bool? sounds,
    bool? pauseDuringMedia,
    bool? moodIndicator,
  }) => GeneralSettings(
    autostart: autostart ?? this.autostart,
    updateCheck: updateCheck ?? this.updateCheck,
    fullscreenOverlay: fullscreenOverlay ?? this.fullscreenOverlay,
    sounds: sounds ?? this.sounds,
    pauseDuringMedia: pauseDuringMedia ?? this.pauseDuringMedia,
    moodIndicator: moodIndicator ?? this.moodIndicator,
  );
}

final generalSettingsProvider =
    AsyncNotifierProvider<GeneralSettingsNotifier, GeneralSettings>(
      GeneralSettingsNotifier.new,
    );

class GeneralSettingsNotifier extends AsyncNotifier<GeneralSettings> {
  @override
  Future<GeneralSettings> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    final general = GeneralSettings(
      autostart: await ref.watch(autostartProvider).isEnabled(),
      updateCheck: await settings.getFlag(
        SettingsRepository.flagUpdateCheck,
        fallback: true,
      ),
      fullscreenOverlay: await settings.getFlag(
        SettingsRepository.flagFullscreenOverlay,
        fallback: true,
      ),
      sounds: await settings.getFlag(
        SettingsRepository.flagSounds,
        fallback: true,
      ),
      pauseDuringMedia: await settings.getFlag(
        SettingsRepository.flagPauseDuringMedia,
        fallback: true,
      ),
      moodIndicator: await settings.getFlag(
        SettingsRepository.flagMoodIndicator,
        fallback: true,
      ),
    );
    ref.read(soundPlayerProvider).enabled = general.sounds;
    ref.read(engineServiceProvider).pauseDuringMedia = general.pauseDuringMedia;
    return general;
  }

  Future<void> setAutostart(bool enabled) async {
    await ref.read(autostartProvider).setEnabled(enabled);
    await _update((s) => s.copyWith(autostart: enabled));
  }

  Future<void> setUpdateCheck(bool enabled) => _persist(
    SettingsRepository.flagUpdateCheck,
    enabled,
    (s) => s.copyWith(updateCheck: enabled),
  );

  Future<void> setFullscreenOverlay(bool enabled) => _persist(
    SettingsRepository.flagFullscreenOverlay,
    enabled,
    (s) => s.copyWith(fullscreenOverlay: enabled),
  );

  Future<void> setSounds(bool enabled) async {
    ref.read(soundPlayerProvider).enabled = enabled;
    await _persist(
      SettingsRepository.flagSounds,
      enabled,
      (s) => s.copyWith(sounds: enabled),
    );
  }

  Future<void> setPauseDuringMedia(bool enabled) async {
    ref.read(engineServiceProvider).pauseDuringMedia = enabled;
    await _persist(
      SettingsRepository.flagPauseDuringMedia,
      enabled,
      (s) => s.copyWith(pauseDuringMedia: enabled),
    );
  }

  Future<void> setMoodIndicator(bool enabled) async {
    final presenter = ref.read(trayMoodPresenterProvider).presenter;
    if (presenter != null) {
      presenter.enabled = enabled;
      await presenter.refresh();
    }
    await _persist(
      SettingsRepository.flagMoodIndicator,
      enabled,
      (s) => s.copyWith(moodIndicator: enabled),
    );
  }

  Future<void> _persist(
    String flag,
    bool value,
    GeneralSettings Function(GeneralSettings) apply,
  ) async {
    await ref.read(settingsRepositoryProvider).setFlag(flag, value);
    await _update(apply);
  }

  Future<void> _update(GeneralSettings Function(GeneralSettings) apply) async {
    state = AsyncData(apply(await future));
  }
}

/// Holds the live tray presenter, which only exists once a tray host has
/// been found. Null on desktops without a status area, so every consumer
/// must cope with its absence.
///
/// A mutable holder rather than a StateProvider: Riverpod 3 dropped
/// StateProvider, and nothing rebuilds on this changing — Settings just needs
/// a handle to push the toggle through to.
class TrayMoodPresenterHolder {
  TrayMoodPresenter? presenter;
}

final trayMoodPresenterProvider = Provider((ref) => TrayMoodPresenterHolder());
