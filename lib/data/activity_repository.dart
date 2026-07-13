import 'package:drift/drift.dart';

import '../core/models/activity.dart';
import 'database.dart';

/// Records and queries raw activity slices.
class ActivityRepository {
  ActivityRepository(this._db);

  final AppDatabase _db;

  Future<void> insertSlice(ActivitySlice slice) => _db
      .into(_db.activitySlices)
      .insert(
        ActivitySlicesCompanion.insert(
          startAt: slice.start,
          endAt: slice.end,
          kind: slice.kind,
        ),
      );

  /// Screen-time stats for the day containing [day] (local time).
  Stream<DayStats> watchSliceStats(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final query = _db.select(_db.activitySlices)
      ..where((t) => t.startAt.isBiggerOrEqualValue(from))
      ..where((t) => t.startAt.isSmallerThanValue(to));
    return query.watch().map(
      (rows) => computeSliceStats(
        rows.map(
          (r) => ActivitySlice(start: r.startAt, end: r.endAt, kind: r.kind),
        ),
      ),
    );
  }

  /// One-shot version of [watchSliceStats], for rollups.
  Future<DayStats> sliceStatsFor(DateTime day) => watchSliceStats(day).first;

  /// Start of the earliest recorded slice, or null with no data.
  Future<DateTime?> earliestSliceStart() async {
    final query = _db.select(_db.activitySlices)
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)])
      ..limit(1);
    return (await query.getSingleOrNull())?.startAt;
  }

  /// Deletes slices already folded into daily rollups.
  Future<int> pruneBefore(DateTime cutoff) => (_db.delete(
    _db.activitySlices,
  )..where((t) => t.endAt.isSmallerThanValue(cutoff))).go();
}
