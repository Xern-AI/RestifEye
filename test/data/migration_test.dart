// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:restifeye/data/database.dart';

const _v1Columns = '''
  "day" INTEGER NOT NULL,
  "screen_seconds" INTEGER NOT NULL,
  "longest_stretch_seconds" INTEGER NOT NULL,
  "breaks_completed" INTEGER NOT NULL,
  "breaks_credited" INTEGER NOT NULL,
  "breaks_escaped" INTEGER NOT NULL,
  "snoozes" INTEGER NOT NULL''';

const _v2Columns = '''
  "idle_seconds" INTEGER NOT NULL DEFAULT 0,
  "away_seconds" INTEGER NOT NULL DEFAULT 0,
  "first_activity_minute" INTEGER NULL,
  "last_activity_minute" INTEGER NULL''';

const _v3Columns = '''
  "watch_seconds" INTEGER NOT NULL DEFAULT 0,
  "focus_runs" INTEGER NOT NULL DEFAULT 0,
  "active_by_hour" TEXT NULL''';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('restifeye_migration');
    file = File(p.join(dir.path, 'RestifEye.db'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> seed({
    required int userVersion,
    required List<String> rollupColumns,
  }) async {
    final raw = NativeDatabase(file);
    final db = _RawAccess(raw);
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS "daily_rollups" '
      '(${rollupColumns.join(',\n')}, PRIMARY KEY ("day"));',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS "setting_rows" '
      '("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));',
    );
    await db.customStatement(
      'INSERT INTO "daily_rollups" '
      '("day","screen_seconds","longest_stretch_seconds","breaks_completed",'
      '"breaks_credited","breaks_escaped","snoozes") '
      'VALUES (0,0,0,0,0,0,0);',
    );
    await db.customStatement('PRAGMA user_version = $userVersion;');
    await db.close();
  }

  Future<Set<String>> columnsOf(AppDatabase db) async {
    final rows = await db
        .customSelect('PRAGMA table_info(daily_rollups)')
        .get();
    return {for (final row in rows) row.read<String>('name')};
  }

  Future<int> userVersionOf(AppDatabase db) async {
    final rows = await db.customSelect('PRAGMA user_version').get();
    return rows.single.read<int>('user_version');
  }

  test('upgrades a clean v2 database to v3', () async {
    await seed(userVersion: 2, rollupColumns: [_v1Columns, _v2Columns]);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(
      await columnsOf(db),
      containsAll(['watch_seconds', 'focus_runs', 'active_by_hour']),
    );
    expect(await userVersionOf(db), 3);
  });

  test(
    'heals a database stranded with every v3 column but version 2',
    () async {
      await seed(
        userVersion: 2,
        rollupColumns: [_v1Columns, _v2Columns, _v3Columns],
      );

      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      expect(await userVersionOf(db), 3);
      expect(
        await columnsOf(db),
        containsAll(['watch_seconds', 'focus_runs', 'active_by_hour']),
      );
    },
  );

  test('heals a database stranded part-way through the v3 step', () async {
    await seed(
      userVersion: 2,
      rollupColumns: [
        _v1Columns,
        _v2Columns,
        '"watch_seconds" INTEGER NOT NULL DEFAULT 0',
      ],
    );

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await userVersionOf(db), 3);
    expect(
      await columnsOf(db),
      containsAll(['watch_seconds', 'focus_runs', 'active_by_hour']),
    );
  });

  test('upgrades a v1 database through both steps', () async {
    await seed(userVersion: 1, rollupColumns: [_v1Columns]);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await userVersionOf(db), 3);
    expect(
      await columnsOf(db),
      containsAll([
        'idle_seconds',
        'away_seconds',
        'first_activity_minute',
        'last_activity_minute',
        'watch_seconds',
        'focus_runs',
        'active_by_hour',
      ]),
    );
  });

  test('reopening a migrated database is a no-op', () async {
    await seed(userVersion: 2, rollupColumns: [_v1Columns, _v2Columns]);

    final first = AppDatabase(NativeDatabase(file));
    await userVersionOf(first);
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    expect(await userVersionOf(second), 3);
  });

  test('preserves rows written before the upgrade', () async {
    await seed(userVersion: 2, rollupColumns: [_v1Columns, _v2Columns]);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final rows = await db.customSelect('SELECT * FROM daily_rollups').get();
    expect(rows, hasLength(1));
    expect(rows.single.read<int>('watch_seconds'), 0);
    expect(rows.single.read<String?>('active_by_hour'), isNull);
  });
}

class _RawAccess extends GeneratedDatabase {
  _RawAccess(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (_) async {}, onUpgrade: (_, _, _) async {});
}
