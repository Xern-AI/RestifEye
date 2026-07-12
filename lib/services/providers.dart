import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../core/models/activity.dart';
import '../data/activity_repository.dart';
import '../data/break_log_repository.dart';
import '../data/database.dart';
import '../data/settings_repository.dart';
import 'engine_service.dart';

/// Concrete instances are created in the bootstrap (or in tests) and
/// injected via ProviderScope overrides — providers here only declare
/// the graph's shape.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('override in bootstrap'),
);

final engineServiceProvider = Provider<EngineService>(
  (ref) => throw UnimplementedError('override in bootstrap'),
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
