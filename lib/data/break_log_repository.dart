import 'package:drift/drift.dart';

import '../core/engine/events.dart';
import 'database.dart';
import 'tables.dart';

/// Break outcome counts for one day.
typedef BreakCounts = ({int completed, int credited, int escaped, int snoozes});

/// Persists engine events into the break log.
class BreakLogRepository {
  BreakLogRepository(this._db);

  final AppDatabase _db;

  /// Records break-related events; engine pause/resume events are not
  /// break history and are skipped.
  Future<void> record(EngineEvent event) {
    final row = switch (event) {
      WarningIssued(:final kind, :final lead) => (
        kind: kind,
        action: BreakAction.warned,
        valueMs: lead.inMilliseconds,
      ),
      BreakStarted(:final kind) => (
        kind: kind,
        action: BreakAction.started,
        valueMs: null,
      ),
      BreakSnoozed(:final kind) => (
        kind: kind,
        action: BreakAction.snoozed,
        valueMs: null,
      ),
      BreakCompleted(:final kind) => (
        kind: kind,
        action: BreakAction.completed,
        valueMs: null,
      ),
      BreakEscaped(:final kind) => (
        kind: kind,
        action: BreakAction.escaped,
        valueMs: null,
      ),
      BreakDeferred(:final kind, :final totalDeferral) => (
        kind: kind,
        action: BreakAction.deferred,
        valueMs: totalDeferral.inMilliseconds,
      ),
      BreakCredited(:final kind, :final awayFor) => (
        kind: kind,
        action: BreakAction.credited,
        valueMs: awayFor.inMilliseconds,
      ),
      EnginePausedByWorkHours() || EngineResumed() => null,
    };
    if (row == null) return Future.value();
    return _db
        .into(_db.breakEventRows)
        .insert(
          BreakEventRowsCompanion.insert(
            at: event.at,
            breakKind: row.kind,
            action: row.action,
            valueMs: Value(row.valueMs),
          ),
        );
  }

  /// Outcome counts for the day containing [day] (local time).
  Stream<BreakCounts> watchDayCounts(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final query = _db.select(_db.breakEventRows)
      ..where((t) => t.at.isBiggerOrEqualValue(from))
      ..where((t) => t.at.isSmallerThanValue(to));
    return query.watch().map((rows) {
      var completed = 0, credited = 0, escaped = 0, snoozes = 0;
      for (final row in rows) {
        switch (row.action) {
          case BreakAction.completed:
            completed++;
          case BreakAction.credited:
            credited++;
          case BreakAction.escaped:
            escaped++;
          case BreakAction.snoozed:
            snoozes++;
          case BreakAction.warned:
          case BreakAction.started:
          case BreakAction.deferred:
            break;
        }
      }
      return (
        completed: completed,
        credited: credited,
        escaped: escaped,
        snoozes: snoozes,
      );
    });
  }
}
