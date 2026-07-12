import 'package:breaktime/core/engine/phase.dart';
import 'package:breaktime/core/models/activity.dart';
import 'package:breaktime/core/models/break_kind.dart';
import 'package:breaktime/data/break_log_repository.dart';
import 'package:breaktime/services/providers.dart';

/// Provider overrides for widget tests: a steady engine phase and fixed
/// stats, no database or D-Bus. (Riverpod 3 doesn't export the Override
/// type, so this list's type is inferred — don't annotate it.)
final testOverrides = [
  enginePhaseProvider.overrideWith(
    (ref) => Stream<EnginePhase>.value(
      const Monitoring(
        nextBreakIn: Duration(minutes: 12, seconds: 34),
        nextBreakKind: BreakKind.micro,
      ),
    ),
  ),
  todaySliceStatsProvider.overrideWith(
    (ref) => Stream<DayStats>.value(
      const DayStats(
        screenTime: Duration(hours: 3, minutes: 20),
        longestStretch: Duration(minutes: 80),
      ),
    ),
  ),
  todayBreakCountsProvider.overrideWith(
    (ref) => Stream<BreakCounts>.value((
      completed: 4,
      credited: 1,
      escaped: 0,
      snoozes: 2,
    )),
  ),
];
