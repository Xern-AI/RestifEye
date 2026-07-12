import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../core/models/activity.dart';
import '../core/models/break_kind.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    ActivitySlices,
    BreakEventRows,
    DailyRollups,
    ExerciseLogRows,
    SettingRows,
    AdviceLogRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Production database at the XDG data location
  /// (`~/.local/share/breaktime/breaktime.db`).
  factory AppDatabase.open() {
    final dataHome =
        Platform.environment['XDG_DATA_HOME'] ??
        p.join(Platform.environment['HOME'] ?? '.', '.local', 'share');
    final dir = Directory(p.join(dataHome, 'breaktime'))
      ..createSync(recursive: true);
    return AppDatabase(
      NativeDatabase.createInBackground(File(p.join(dir.path, 'breaktime.db'))),
    );
  }

  /// Throwaway in-memory database for tests.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
