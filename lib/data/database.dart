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
  /// (`~/.local/share/RestifEye/RestifEye.db`).
  factory AppDatabase.open() {
    final dataHome =
        Platform.environment['XDG_DATA_HOME'] ??
        p.join(Platform.environment['HOME'] ?? '.', '.local', 'share');
    final dir = Directory(p.join(dataHome, 'RestifEye'));
    // One-shot migration from the pre-rename install (the app shipped as
    // BreakTime before v0.1.0 and kept its data in `breaktime/breaktime.db`).
    final legacyDir = Directory(p.join(dataHome, 'breaktime'));
    if (!dir.existsSync() && legacyDir.existsSync()) {
      legacyDir.renameSync(dir.path);
    }
    dir.createSync(recursive: true);
    if (!File(p.join(dir.path, 'RestifEye.db')).existsSync()) {
      for (final ext in ['', '-wal', '-shm']) {
        final legacyDb = File(p.join(dir.path, 'breaktime.db$ext'));
        if (legacyDb.existsSync()) {
          legacyDb.renameSync(p.join(dir.path, 'RestifEye.db$ext'));
        }
      }
    }
    return AppDatabase(
      NativeDatabase.createInBackground(File(p.join(dir.path, 'RestifEye.db'))),
    );
  }

  /// Throwaway in-memory database for tests.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 2;

  /// v1 → v2 adds the idle/away/workday-span columns to daily_rollups.
  /// Additive and defaulted, so existing rows survive untouched: a user's
  /// history is theirs, and an upgrade must never quietly drop it.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(dailyRollups, dailyRollups.idleSeconds);
        await m.addColumn(dailyRollups, dailyRollups.awaySeconds);
        await m.addColumn(dailyRollups, dailyRollups.firstActivityMinute);
        await m.addColumn(dailyRollups, dailyRollups.lastActivityMinute);
      }
    },
  );
}
