// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

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

  static String get _dataHome =>
      Platform.environment['XDG_DATA_HOME'] ??
      p.join(Platform.environment['HOME'] ?? '.', '.local', 'share');

  /// Where the production database lives, resolved without touching the
  /// disk. Startup failures name this path, so it must stay readable even
  /// when opening the database is exactly what went wrong.
  static String get productionPath =>
      p.join(_dataHome, 'RestifEye', 'RestifEye.db');

  /// Production database at the XDG data location
  /// (`~/.local/share/RestifEye/RestifEye.db`).
  factory AppDatabase.open() {
    final dataHome = _dataHome;
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
  int get schemaVersion => 3;

  /// v1 → v2 adds the idle/away/workday-span columns to daily_rollups;
  /// v2 → v3 adds watch time, deep-work runs and the hourly profile.
  /// Every step is additive and defaulted, so existing rows survive
  /// untouched: a user's history is theirs, and an upgrade must never
  /// quietly drop it. Days rolled up before a column existed keep reading
  /// as "no data" rather than as zero, wherever the difference matters.
  ///
  /// Drift runs [onUpgrade] outside a transaction and stamps `user_version`
  /// only after it returns, so a process killed mid-migration leaves the
  /// columns added but the version behind — and every later launch then dies
  /// on `duplicate column`. The steps below are therefore both atomic (one
  /// transaction, so a kill rolls back) and idempotent (each column is
  /// skipped if already present, so a database already stranded that way
  /// heals itself on the next launch).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await m.database.transaction(() async {
        final present = await _columnNames(
          m.database,
          dailyRollups.actualTableName,
        );
        Future<void> add(GeneratedColumn<Object> column) =>
            present.contains(column.name)
            ? Future<void>.value()
            : m.addColumn(dailyRollups, column);

        if (from < 2) {
          await add(dailyRollups.idleSeconds);
          await add(dailyRollups.awaySeconds);
          await add(dailyRollups.firstActivityMinute);
          await add(dailyRollups.lastActivityMinute);
        }
        if (from < 3) {
          await add(dailyRollups.watchSeconds);
          await add(dailyRollups.focusRuns);
          await add(dailyRollups.activeByHour);
        }
      });
    },
  );

  static Future<Set<String>> _columnNames(
    GeneratedDatabase db,
    String table,
  ) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return {for (final row in rows) row.read<String>('name')};
  }
}
