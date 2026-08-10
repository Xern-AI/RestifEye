// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'database.dart';

/// Records which exercise was shown for each break and whether the user
/// completed it — feeds analytics and future deck tuning.
class ExerciseLogRepository {
  ExerciseLogRepository(this._db);

  final AppDatabase _db;

  Future<void> record({
    required String exerciseId,
    required bool completed,
    required DateTime at,
  }) => _db
      .into(_db.exerciseLogRows)
      .insert(
        ExerciseLogRowsCompanion.insert(
          at: at,
          exerciseId: exerciseId,
          completed: completed,
        ),
      );
}
