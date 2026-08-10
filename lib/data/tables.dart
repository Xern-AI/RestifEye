// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:drift/drift.dart';

import '../core/models/activity.dart';
import '../core/models/break_kind.dart';

/// Raw activity spans; pruned after daily rollup to keep the DB tiny.
@DataClassName('ActivitySliceRow')
class ActivitySlices extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  IntColumn get kind => intEnum<SliceKind>()();
}

/// What happened to each break, as it happened.
class BreakEventRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  IntColumn get breakKind => intEnum<BreakKind>()();
  IntColumn get action => intEnum<BreakAction>()();

  /// Context duration in ms (warning lead, away span, total deferral).
  IntColumn get valueMs => integer().nullable()();
}

/// One row per day; analytics query these, never the raw slices.
///
/// Columns added in schema v2 are nullable with defaults so that days rolled
/// up before the upgrade keep working — they simply have no idle/away figures,
/// which is honest: we cannot invent data we discarded.
class DailyRollups extends Table {
  DateTimeColumn get day => dateTime()();
  IntColumn get screenSeconds => integer()();
  IntColumn get longestStretchSeconds => integer()();
  IntColumn get breaksCompleted => integer()();
  IntColumn get breaksCredited => integer()();
  IntColumn get breaksEscaped => integer()();
  IntColumn get snoozes => integer()();

  /// v2: at the machine but not touching it.
  IntColumn get idleSeconds => integer().withDefault(const Constant(0))();

  /// v2: locked or suspended.
  IntColumn get awaySeconds => integer().withDefault(const Constant(0))();

  /// v2: first and last activity, as minutes since local midnight.
  IntColumn get firstActivityMinute => integer().nullable()();
  IntColumn get lastActivityMinute => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {day};
}

class ExerciseLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get exerciseId => text()();
  BoolColumn get completed => boolean()();
}

/// Typed key-value store: app flags, break config JSON, engine snapshot.
class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class AdviceLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get shownAt => dateTime()();
  TextColumn get ruleId => text()();
}

/// Persisted lifecycle of a break, mirroring the engine's events.
/// Stored by index — only ever append new values.
enum BreakAction {
  warned,
  started,
  snoozed,
  completed,
  escaped,
  deferred,
  credited,
  skipped,
}
