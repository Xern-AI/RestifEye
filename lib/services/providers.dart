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
import 'advice_engine.dart';
import 'engine_service.dart';
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

/// Today's screen time / longest stretch, reactive to new slices.
final todaySliceStatsProvider = StreamProvider<DayStats>(
  (ref) =>
      ref.watch(activityRepositoryProvider).watchSliceStats(DateTime.now()),
);

/// Today's break outcome counts, reactive to new break events.
final todayBreakCountsProvider = StreamProvider<BreakCounts>(
  (ref) => ref.watch(breakLogRepositoryProvider).watchDayCounts(DateTime.now()),
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
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final from = switch (range) {
    AnalyticsRange.week => today.subtract(const Duration(days: 7)),
    AnalyticsRange.month => today.subtract(const Duration(days: 30)),
    AnalyticsRange.year => DateTime(today.year - 1, today.month, today.day),
  };
  return ref.watch(rollupRepositoryProvider).watchRange(from, today);
});

/// Current advice from the last four weeks of rollups.
final adviceProvider = StreamProvider<List<Advice>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(rollupRepositoryProvider)
      .watchRange(today.subtract(const Duration(days: 28)), today)
      .map(evaluateAdvice);
});

/// Engine pause toggle, mirrored for the UI.
final pausedProvider = NotifierProvider<PausedNotifier, bool>(
  PausedNotifier.new,
);

class PausedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool paused) {
    state = paused;
    ref.read(engineServiceProvider).engine.setPausedByUser(paused);
  }
}

/// Autostart, update-check, and break-window switches (persisted).
typedef GeneralSettings = ({
  bool autostart,
  bool updateCheck,
  bool fullscreenOverlay,
});

final generalSettingsProvider =
    AsyncNotifierProvider<GeneralSettingsNotifier, GeneralSettings>(
      GeneralSettingsNotifier.new,
    );

class GeneralSettingsNotifier extends AsyncNotifier<GeneralSettings> {
  @override
  Future<GeneralSettings> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    final autostart = await ref.watch(autostartProvider).isEnabled();
    final updateCheck = await settings.getFlag(
      SettingsRepository.flagUpdateCheck,
      fallback: true,
    );
    final fullscreenOverlay = await settings.getFlag(
      SettingsRepository.flagFullscreenOverlay,
      fallback: true,
    );
    return (
      autostart: autostart,
      updateCheck: updateCheck,
      fullscreenOverlay: fullscreenOverlay,
    );
  }

  Future<void> setAutostart(bool enabled) async {
    await ref.read(autostartProvider).setEnabled(enabled);
    final previous = await future;
    state = AsyncData((
      autostart: enabled,
      updateCheck: previous.updateCheck,
      fullscreenOverlay: previous.fullscreenOverlay,
    ));
  }

  Future<void> setUpdateCheck(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .setFlag(SettingsRepository.flagUpdateCheck, enabled);
    final previous = await future;
    state = AsyncData((
      autostart: previous.autostart,
      updateCheck: enabled,
      fullscreenOverlay: previous.fullscreenOverlay,
    ));
  }

  Future<void> setFullscreenOverlay(bool enabled) async {
    await ref
        .read(settingsRepositoryProvider)
        .setFlag(SettingsRepository.flagFullscreenOverlay, enabled);
    final previous = await future;
    state = AsyncData((
      autostart: previous.autostart,
      updateCheck: previous.updateCheck,
      fullscreenOverlay: enabled,
    ));
  }
}
