import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../core/models/activity.dart';
import '../core/models/break_config.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/database.dart';
import '../data/exercise_log_repository.dart';
import '../data/settings_repository.dart';
import '../platform/interfaces/overlay_controller.dart';
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
