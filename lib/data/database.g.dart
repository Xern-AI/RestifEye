// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ActivitySlicesTable extends ActivitySlices
    with TableInfo<$ActivitySlicesTable, ActivitySliceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitySlicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SliceKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<SliceKind>($ActivitySlicesTable.$converterkind);
  @override
  List<GeneratedColumn> get $columns => [id, startAt, endAt, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_slices';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivitySliceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivitySliceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivitySliceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      )!,
      kind: $ActivitySlicesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
    );
  }

  @override
  $ActivitySlicesTable createAlias(String alias) {
    return $ActivitySlicesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SliceKind, int, int> $converterkind =
      const EnumIndexConverter<SliceKind>(SliceKind.values);
}

class ActivitySliceRow extends DataClass
    implements Insertable<ActivitySliceRow> {
  final int id;
  final DateTime startAt;
  final DateTime endAt;
  final SliceKind kind;
  const ActivitySliceRow({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_at'] = Variable<DateTime>(startAt);
    map['end_at'] = Variable<DateTime>(endAt);
    {
      map['kind'] = Variable<int>(
        $ActivitySlicesTable.$converterkind.toSql(kind),
      );
    }
    return map;
  }

  ActivitySlicesCompanion toCompanion(bool nullToAbsent) {
    return ActivitySlicesCompanion(
      id: Value(id),
      startAt: Value(startAt),
      endAt: Value(endAt),
      kind: Value(kind),
    );
  }

  factory ActivitySliceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivitySliceRow(
      id: serializer.fromJson<int>(json['id']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime>(json['endAt']),
      kind: $ActivitySlicesTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime>(endAt),
      'kind': serializer.toJson<int>(
        $ActivitySlicesTable.$converterkind.toJson(kind),
      ),
    };
  }

  ActivitySliceRow copyWith({
    int? id,
    DateTime? startAt,
    DateTime? endAt,
    SliceKind? kind,
  }) => ActivitySliceRow(
    id: id ?? this.id,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    kind: kind ?? this.kind,
  );
  ActivitySliceRow copyWithCompanion(ActivitySlicesCompanion data) {
    return ActivitySliceRow(
      id: data.id.present ? data.id.value : this.id,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySliceRow(')
          ..write('id: $id, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startAt, endAt, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivitySliceRow &&
          other.id == this.id &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.kind == this.kind);
}

class ActivitySlicesCompanion extends UpdateCompanion<ActivitySliceRow> {
  final Value<int> id;
  final Value<DateTime> startAt;
  final Value<DateTime> endAt;
  final Value<SliceKind> kind;
  const ActivitySlicesCompanion({
    this.id = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.kind = const Value.absent(),
  });
  ActivitySlicesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startAt,
    required DateTime endAt,
    required SliceKind kind,
  }) : startAt = Value(startAt),
       endAt = Value(endAt),
       kind = Value(kind);
  static Insertable<ActivitySliceRow> custom({
    Expression<int>? id,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<int>? kind,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (kind != null) 'kind': kind,
    });
  }

  ActivitySlicesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startAt,
    Value<DateTime>? endAt,
    Value<SliceKind>? kind,
  }) {
    return ActivitySlicesCompanion(
      id: id ?? this.id,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      kind: kind ?? this.kind,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $ActivitySlicesTable.$converterkind.toSql(kind.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitySlicesCompanion(')
          ..write('id: $id, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }
}

class $BreakEventRowsTable extends BreakEventRows
    with TableInfo<$BreakEventRowsTable, BreakEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BreakEventRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BreakKind, int> breakKind =
      GeneratedColumn<int>(
        'break_kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<BreakKind>($BreakEventRowsTable.$converterbreakKind);
  @override
  late final GeneratedColumnWithTypeConverter<BreakAction, int> action =
      GeneratedColumn<int>(
        'action',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<BreakAction>($BreakEventRowsTable.$converteraction);
  static const VerificationMeta _valueMsMeta = const VerificationMeta(
    'valueMs',
  );
  @override
  late final GeneratedColumn<int> valueMs = GeneratedColumn<int>(
    'value_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, breakKind, action, valueMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'break_event_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreakEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('value_ms')) {
      context.handle(
        _valueMsMeta,
        valueMs.isAcceptableOrUnknown(data['value_ms']!, _valueMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreakEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreakEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      breakKind: $BreakEventRowsTable.$converterbreakKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}break_kind'],
        )!,
      ),
      action: $BreakEventRowsTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}action'],
        )!,
      ),
      valueMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_ms'],
      ),
    );
  }

  @override
  $BreakEventRowsTable createAlias(String alias) {
    return $BreakEventRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BreakKind, int, int> $converterbreakKind =
      const EnumIndexConverter<BreakKind>(BreakKind.values);
  static JsonTypeConverter2<BreakAction, int, int> $converteraction =
      const EnumIndexConverter<BreakAction>(BreakAction.values);
}

class BreakEventRow extends DataClass implements Insertable<BreakEventRow> {
  final int id;
  final DateTime at;
  final BreakKind breakKind;
  final BreakAction action;

  /// Context duration in ms (warning lead, away span, total deferral).
  final int? valueMs;
  const BreakEventRow({
    required this.id,
    required this.at,
    required this.breakKind,
    required this.action,
    this.valueMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    {
      map['break_kind'] = Variable<int>(
        $BreakEventRowsTable.$converterbreakKind.toSql(breakKind),
      );
    }
    {
      map['action'] = Variable<int>(
        $BreakEventRowsTable.$converteraction.toSql(action),
      );
    }
    if (!nullToAbsent || valueMs != null) {
      map['value_ms'] = Variable<int>(valueMs);
    }
    return map;
  }

  BreakEventRowsCompanion toCompanion(bool nullToAbsent) {
    return BreakEventRowsCompanion(
      id: Value(id),
      at: Value(at),
      breakKind: Value(breakKind),
      action: Value(action),
      valueMs: valueMs == null && nullToAbsent
          ? const Value.absent()
          : Value(valueMs),
    );
  }

  factory BreakEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreakEventRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      breakKind: $BreakEventRowsTable.$converterbreakKind.fromJson(
        serializer.fromJson<int>(json['breakKind']),
      ),
      action: $BreakEventRowsTable.$converteraction.fromJson(
        serializer.fromJson<int>(json['action']),
      ),
      valueMs: serializer.fromJson<int?>(json['valueMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'breakKind': serializer.toJson<int>(
        $BreakEventRowsTable.$converterbreakKind.toJson(breakKind),
      ),
      'action': serializer.toJson<int>(
        $BreakEventRowsTable.$converteraction.toJson(action),
      ),
      'valueMs': serializer.toJson<int?>(valueMs),
    };
  }

  BreakEventRow copyWith({
    int? id,
    DateTime? at,
    BreakKind? breakKind,
    BreakAction? action,
    Value<int?> valueMs = const Value.absent(),
  }) => BreakEventRow(
    id: id ?? this.id,
    at: at ?? this.at,
    breakKind: breakKind ?? this.breakKind,
    action: action ?? this.action,
    valueMs: valueMs.present ? valueMs.value : this.valueMs,
  );
  BreakEventRow copyWithCompanion(BreakEventRowsCompanion data) {
    return BreakEventRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      breakKind: data.breakKind.present ? data.breakKind.value : this.breakKind,
      action: data.action.present ? data.action.value : this.action,
      valueMs: data.valueMs.present ? data.valueMs.value : this.valueMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreakEventRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('breakKind: $breakKind, ')
          ..write('action: $action, ')
          ..write('valueMs: $valueMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, breakKind, action, valueMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreakEventRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.breakKind == this.breakKind &&
          other.action == this.action &&
          other.valueMs == this.valueMs);
}

class BreakEventRowsCompanion extends UpdateCompanion<BreakEventRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<BreakKind> breakKind;
  final Value<BreakAction> action;
  final Value<int?> valueMs;
  const BreakEventRowsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.breakKind = const Value.absent(),
    this.action = const Value.absent(),
    this.valueMs = const Value.absent(),
  });
  BreakEventRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required BreakKind breakKind,
    required BreakAction action,
    this.valueMs = const Value.absent(),
  }) : at = Value(at),
       breakKind = Value(breakKind),
       action = Value(action);
  static Insertable<BreakEventRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<int>? breakKind,
    Expression<int>? action,
    Expression<int>? valueMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (breakKind != null) 'break_kind': breakKind,
      if (action != null) 'action': action,
      if (valueMs != null) 'value_ms': valueMs,
    });
  }

  BreakEventRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<BreakKind>? breakKind,
    Value<BreakAction>? action,
    Value<int?>? valueMs,
  }) {
    return BreakEventRowsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      breakKind: breakKind ?? this.breakKind,
      action: action ?? this.action,
      valueMs: valueMs ?? this.valueMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (breakKind.present) {
      map['break_kind'] = Variable<int>(
        $BreakEventRowsTable.$converterbreakKind.toSql(breakKind.value),
      );
    }
    if (action.present) {
      map['action'] = Variable<int>(
        $BreakEventRowsTable.$converteraction.toSql(action.value),
      );
    }
    if (valueMs.present) {
      map['value_ms'] = Variable<int>(valueMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BreakEventRowsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('breakKind: $breakKind, ')
          ..write('action: $action, ')
          ..write('valueMs: $valueMs')
          ..write(')'))
        .toString();
  }
}

class $DailyRollupsTable extends DailyRollups
    with TableInfo<$DailyRollupsTable, DailyRollup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRollupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _screenSecondsMeta = const VerificationMeta(
    'screenSeconds',
  );
  @override
  late final GeneratedColumn<int> screenSeconds = GeneratedColumn<int>(
    'screen_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longestStretchSecondsMeta =
      const VerificationMeta('longestStretchSeconds');
  @override
  late final GeneratedColumn<int> longestStretchSeconds = GeneratedColumn<int>(
    'longest_stretch_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breaksCompletedMeta = const VerificationMeta(
    'breaksCompleted',
  );
  @override
  late final GeneratedColumn<int> breaksCompleted = GeneratedColumn<int>(
    'breaks_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breaksCreditedMeta = const VerificationMeta(
    'breaksCredited',
  );
  @override
  late final GeneratedColumn<int> breaksCredited = GeneratedColumn<int>(
    'breaks_credited',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breaksEscapedMeta = const VerificationMeta(
    'breaksEscaped',
  );
  @override
  late final GeneratedColumn<int> breaksEscaped = GeneratedColumn<int>(
    'breaks_escaped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozesMeta = const VerificationMeta(
    'snoozes',
  );
  @override
  late final GeneratedColumn<int> snoozes = GeneratedColumn<int>(
    'snoozes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idleSecondsMeta = const VerificationMeta(
    'idleSeconds',
  );
  @override
  late final GeneratedColumn<int> idleSeconds = GeneratedColumn<int>(
    'idle_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awaySecondsMeta = const VerificationMeta(
    'awaySeconds',
  );
  @override
  late final GeneratedColumn<int> awaySeconds = GeneratedColumn<int>(
    'away_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstActivityMinuteMeta =
      const VerificationMeta('firstActivityMinute');
  @override
  late final GeneratedColumn<int> firstActivityMinute = GeneratedColumn<int>(
    'first_activity_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastActivityMinuteMeta =
      const VerificationMeta('lastActivityMinute');
  @override
  late final GeneratedColumn<int> lastActivityMinute = GeneratedColumn<int>(
    'last_activity_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    screenSeconds,
    longestStretchSeconds,
    breaksCompleted,
    breaksCredited,
    breaksEscaped,
    snoozes,
    idleSeconds,
    awaySeconds,
    firstActivityMinute,
    lastActivityMinute,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_rollups';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyRollup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('screen_seconds')) {
      context.handle(
        _screenSecondsMeta,
        screenSeconds.isAcceptableOrUnknown(
          data['screen_seconds']!,
          _screenSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_screenSecondsMeta);
    }
    if (data.containsKey('longest_stretch_seconds')) {
      context.handle(
        _longestStretchSecondsMeta,
        longestStretchSeconds.isAcceptableOrUnknown(
          data['longest_stretch_seconds']!,
          _longestStretchSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longestStretchSecondsMeta);
    }
    if (data.containsKey('breaks_completed')) {
      context.handle(
        _breaksCompletedMeta,
        breaksCompleted.isAcceptableOrUnknown(
          data['breaks_completed']!,
          _breaksCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breaksCompletedMeta);
    }
    if (data.containsKey('breaks_credited')) {
      context.handle(
        _breaksCreditedMeta,
        breaksCredited.isAcceptableOrUnknown(
          data['breaks_credited']!,
          _breaksCreditedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breaksCreditedMeta);
    }
    if (data.containsKey('breaks_escaped')) {
      context.handle(
        _breaksEscapedMeta,
        breaksEscaped.isAcceptableOrUnknown(
          data['breaks_escaped']!,
          _breaksEscapedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_breaksEscapedMeta);
    }
    if (data.containsKey('snoozes')) {
      context.handle(
        _snoozesMeta,
        snoozes.isAcceptableOrUnknown(data['snoozes']!, _snoozesMeta),
      );
    } else if (isInserting) {
      context.missing(_snoozesMeta);
    }
    if (data.containsKey('idle_seconds')) {
      context.handle(
        _idleSecondsMeta,
        idleSeconds.isAcceptableOrUnknown(
          data['idle_seconds']!,
          _idleSecondsMeta,
        ),
      );
    }
    if (data.containsKey('away_seconds')) {
      context.handle(
        _awaySecondsMeta,
        awaySeconds.isAcceptableOrUnknown(
          data['away_seconds']!,
          _awaySecondsMeta,
        ),
      );
    }
    if (data.containsKey('first_activity_minute')) {
      context.handle(
        _firstActivityMinuteMeta,
        firstActivityMinute.isAcceptableOrUnknown(
          data['first_activity_minute']!,
          _firstActivityMinuteMeta,
        ),
      );
    }
    if (data.containsKey('last_activity_minute')) {
      context.handle(
        _lastActivityMinuteMeta,
        lastActivityMinute.isAcceptableOrUnknown(
          data['last_activity_minute']!,
          _lastActivityMinuteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyRollup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRollup(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      screenSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}screen_seconds'],
      )!,
      longestStretchSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_stretch_seconds'],
      )!,
      breaksCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}breaks_completed'],
      )!,
      breaksCredited: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}breaks_credited'],
      )!,
      breaksEscaped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}breaks_escaped'],
      )!,
      snoozes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snoozes'],
      )!,
      idleSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}idle_seconds'],
      )!,
      awaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}away_seconds'],
      )!,
      firstActivityMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_activity_minute'],
      ),
      lastActivityMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_activity_minute'],
      ),
    );
  }

  @override
  $DailyRollupsTable createAlias(String alias) {
    return $DailyRollupsTable(attachedDatabase, alias);
  }
}

class DailyRollup extends DataClass implements Insertable<DailyRollup> {
  final DateTime day;
  final int screenSeconds;
  final int longestStretchSeconds;
  final int breaksCompleted;
  final int breaksCredited;
  final int breaksEscaped;
  final int snoozes;

  /// v2: at the machine but not touching it.
  final int idleSeconds;

  /// v2: locked or suspended.
  final int awaySeconds;

  /// v2: first and last activity, as minutes since local midnight.
  final int? firstActivityMinute;
  final int? lastActivityMinute;
  const DailyRollup({
    required this.day,
    required this.screenSeconds,
    required this.longestStretchSeconds,
    required this.breaksCompleted,
    required this.breaksCredited,
    required this.breaksEscaped,
    required this.snoozes,
    required this.idleSeconds,
    required this.awaySeconds,
    this.firstActivityMinute,
    this.lastActivityMinute,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['screen_seconds'] = Variable<int>(screenSeconds);
    map['longest_stretch_seconds'] = Variable<int>(longestStretchSeconds);
    map['breaks_completed'] = Variable<int>(breaksCompleted);
    map['breaks_credited'] = Variable<int>(breaksCredited);
    map['breaks_escaped'] = Variable<int>(breaksEscaped);
    map['snoozes'] = Variable<int>(snoozes);
    map['idle_seconds'] = Variable<int>(idleSeconds);
    map['away_seconds'] = Variable<int>(awaySeconds);
    if (!nullToAbsent || firstActivityMinute != null) {
      map['first_activity_minute'] = Variable<int>(firstActivityMinute);
    }
    if (!nullToAbsent || lastActivityMinute != null) {
      map['last_activity_minute'] = Variable<int>(lastActivityMinute);
    }
    return map;
  }

  DailyRollupsCompanion toCompanion(bool nullToAbsent) {
    return DailyRollupsCompanion(
      day: Value(day),
      screenSeconds: Value(screenSeconds),
      longestStretchSeconds: Value(longestStretchSeconds),
      breaksCompleted: Value(breaksCompleted),
      breaksCredited: Value(breaksCredited),
      breaksEscaped: Value(breaksEscaped),
      snoozes: Value(snoozes),
      idleSeconds: Value(idleSeconds),
      awaySeconds: Value(awaySeconds),
      firstActivityMinute: firstActivityMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(firstActivityMinute),
      lastActivityMinute: lastActivityMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityMinute),
    );
  }

  factory DailyRollup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRollup(
      day: serializer.fromJson<DateTime>(json['day']),
      screenSeconds: serializer.fromJson<int>(json['screenSeconds']),
      longestStretchSeconds: serializer.fromJson<int>(
        json['longestStretchSeconds'],
      ),
      breaksCompleted: serializer.fromJson<int>(json['breaksCompleted']),
      breaksCredited: serializer.fromJson<int>(json['breaksCredited']),
      breaksEscaped: serializer.fromJson<int>(json['breaksEscaped']),
      snoozes: serializer.fromJson<int>(json['snoozes']),
      idleSeconds: serializer.fromJson<int>(json['idleSeconds']),
      awaySeconds: serializer.fromJson<int>(json['awaySeconds']),
      firstActivityMinute: serializer.fromJson<int?>(
        json['firstActivityMinute'],
      ),
      lastActivityMinute: serializer.fromJson<int?>(json['lastActivityMinute']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'screenSeconds': serializer.toJson<int>(screenSeconds),
      'longestStretchSeconds': serializer.toJson<int>(longestStretchSeconds),
      'breaksCompleted': serializer.toJson<int>(breaksCompleted),
      'breaksCredited': serializer.toJson<int>(breaksCredited),
      'breaksEscaped': serializer.toJson<int>(breaksEscaped),
      'snoozes': serializer.toJson<int>(snoozes),
      'idleSeconds': serializer.toJson<int>(idleSeconds),
      'awaySeconds': serializer.toJson<int>(awaySeconds),
      'firstActivityMinute': serializer.toJson<int?>(firstActivityMinute),
      'lastActivityMinute': serializer.toJson<int?>(lastActivityMinute),
    };
  }

  DailyRollup copyWith({
    DateTime? day,
    int? screenSeconds,
    int? longestStretchSeconds,
    int? breaksCompleted,
    int? breaksCredited,
    int? breaksEscaped,
    int? snoozes,
    int? idleSeconds,
    int? awaySeconds,
    Value<int?> firstActivityMinute = const Value.absent(),
    Value<int?> lastActivityMinute = const Value.absent(),
  }) => DailyRollup(
    day: day ?? this.day,
    screenSeconds: screenSeconds ?? this.screenSeconds,
    longestStretchSeconds: longestStretchSeconds ?? this.longestStretchSeconds,
    breaksCompleted: breaksCompleted ?? this.breaksCompleted,
    breaksCredited: breaksCredited ?? this.breaksCredited,
    breaksEscaped: breaksEscaped ?? this.breaksEscaped,
    snoozes: snoozes ?? this.snoozes,
    idleSeconds: idleSeconds ?? this.idleSeconds,
    awaySeconds: awaySeconds ?? this.awaySeconds,
    firstActivityMinute: firstActivityMinute.present
        ? firstActivityMinute.value
        : this.firstActivityMinute,
    lastActivityMinute: lastActivityMinute.present
        ? lastActivityMinute.value
        : this.lastActivityMinute,
  );
  DailyRollup copyWithCompanion(DailyRollupsCompanion data) {
    return DailyRollup(
      day: data.day.present ? data.day.value : this.day,
      screenSeconds: data.screenSeconds.present
          ? data.screenSeconds.value
          : this.screenSeconds,
      longestStretchSeconds: data.longestStretchSeconds.present
          ? data.longestStretchSeconds.value
          : this.longestStretchSeconds,
      breaksCompleted: data.breaksCompleted.present
          ? data.breaksCompleted.value
          : this.breaksCompleted,
      breaksCredited: data.breaksCredited.present
          ? data.breaksCredited.value
          : this.breaksCredited,
      breaksEscaped: data.breaksEscaped.present
          ? data.breaksEscaped.value
          : this.breaksEscaped,
      snoozes: data.snoozes.present ? data.snoozes.value : this.snoozes,
      idleSeconds: data.idleSeconds.present
          ? data.idleSeconds.value
          : this.idleSeconds,
      awaySeconds: data.awaySeconds.present
          ? data.awaySeconds.value
          : this.awaySeconds,
      firstActivityMinute: data.firstActivityMinute.present
          ? data.firstActivityMinute.value
          : this.firstActivityMinute,
      lastActivityMinute: data.lastActivityMinute.present
          ? data.lastActivityMinute.value
          : this.lastActivityMinute,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollup(')
          ..write('day: $day, ')
          ..write('screenSeconds: $screenSeconds, ')
          ..write('longestStretchSeconds: $longestStretchSeconds, ')
          ..write('breaksCompleted: $breaksCompleted, ')
          ..write('breaksCredited: $breaksCredited, ')
          ..write('breaksEscaped: $breaksEscaped, ')
          ..write('snoozes: $snoozes, ')
          ..write('idleSeconds: $idleSeconds, ')
          ..write('awaySeconds: $awaySeconds, ')
          ..write('firstActivityMinute: $firstActivityMinute, ')
          ..write('lastActivityMinute: $lastActivityMinute')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    day,
    screenSeconds,
    longestStretchSeconds,
    breaksCompleted,
    breaksCredited,
    breaksEscaped,
    snoozes,
    idleSeconds,
    awaySeconds,
    firstActivityMinute,
    lastActivityMinute,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRollup &&
          other.day == this.day &&
          other.screenSeconds == this.screenSeconds &&
          other.longestStretchSeconds == this.longestStretchSeconds &&
          other.breaksCompleted == this.breaksCompleted &&
          other.breaksCredited == this.breaksCredited &&
          other.breaksEscaped == this.breaksEscaped &&
          other.snoozes == this.snoozes &&
          other.idleSeconds == this.idleSeconds &&
          other.awaySeconds == this.awaySeconds &&
          other.firstActivityMinute == this.firstActivityMinute &&
          other.lastActivityMinute == this.lastActivityMinute);
}

class DailyRollupsCompanion extends UpdateCompanion<DailyRollup> {
  final Value<DateTime> day;
  final Value<int> screenSeconds;
  final Value<int> longestStretchSeconds;
  final Value<int> breaksCompleted;
  final Value<int> breaksCredited;
  final Value<int> breaksEscaped;
  final Value<int> snoozes;
  final Value<int> idleSeconds;
  final Value<int> awaySeconds;
  final Value<int?> firstActivityMinute;
  final Value<int?> lastActivityMinute;
  final Value<int> rowid;
  const DailyRollupsCompanion({
    this.day = const Value.absent(),
    this.screenSeconds = const Value.absent(),
    this.longestStretchSeconds = const Value.absent(),
    this.breaksCompleted = const Value.absent(),
    this.breaksCredited = const Value.absent(),
    this.breaksEscaped = const Value.absent(),
    this.snoozes = const Value.absent(),
    this.idleSeconds = const Value.absent(),
    this.awaySeconds = const Value.absent(),
    this.firstActivityMinute = const Value.absent(),
    this.lastActivityMinute = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyRollupsCompanion.insert({
    required DateTime day,
    required int screenSeconds,
    required int longestStretchSeconds,
    required int breaksCompleted,
    required int breaksCredited,
    required int breaksEscaped,
    required int snoozes,
    this.idleSeconds = const Value.absent(),
    this.awaySeconds = const Value.absent(),
    this.firstActivityMinute = const Value.absent(),
    this.lastActivityMinute = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       screenSeconds = Value(screenSeconds),
       longestStretchSeconds = Value(longestStretchSeconds),
       breaksCompleted = Value(breaksCompleted),
       breaksCredited = Value(breaksCredited),
       breaksEscaped = Value(breaksEscaped),
       snoozes = Value(snoozes);
  static Insertable<DailyRollup> custom({
    Expression<DateTime>? day,
    Expression<int>? screenSeconds,
    Expression<int>? longestStretchSeconds,
    Expression<int>? breaksCompleted,
    Expression<int>? breaksCredited,
    Expression<int>? breaksEscaped,
    Expression<int>? snoozes,
    Expression<int>? idleSeconds,
    Expression<int>? awaySeconds,
    Expression<int>? firstActivityMinute,
    Expression<int>? lastActivityMinute,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (screenSeconds != null) 'screen_seconds': screenSeconds,
      if (longestStretchSeconds != null)
        'longest_stretch_seconds': longestStretchSeconds,
      if (breaksCompleted != null) 'breaks_completed': breaksCompleted,
      if (breaksCredited != null) 'breaks_credited': breaksCredited,
      if (breaksEscaped != null) 'breaks_escaped': breaksEscaped,
      if (snoozes != null) 'snoozes': snoozes,
      if (idleSeconds != null) 'idle_seconds': idleSeconds,
      if (awaySeconds != null) 'away_seconds': awaySeconds,
      if (firstActivityMinute != null)
        'first_activity_minute': firstActivityMinute,
      if (lastActivityMinute != null)
        'last_activity_minute': lastActivityMinute,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyRollupsCompanion copyWith({
    Value<DateTime>? day,
    Value<int>? screenSeconds,
    Value<int>? longestStretchSeconds,
    Value<int>? breaksCompleted,
    Value<int>? breaksCredited,
    Value<int>? breaksEscaped,
    Value<int>? snoozes,
    Value<int>? idleSeconds,
    Value<int>? awaySeconds,
    Value<int?>? firstActivityMinute,
    Value<int?>? lastActivityMinute,
    Value<int>? rowid,
  }) {
    return DailyRollupsCompanion(
      day: day ?? this.day,
      screenSeconds: screenSeconds ?? this.screenSeconds,
      longestStretchSeconds:
          longestStretchSeconds ?? this.longestStretchSeconds,
      breaksCompleted: breaksCompleted ?? this.breaksCompleted,
      breaksCredited: breaksCredited ?? this.breaksCredited,
      breaksEscaped: breaksEscaped ?? this.breaksEscaped,
      snoozes: snoozes ?? this.snoozes,
      idleSeconds: idleSeconds ?? this.idleSeconds,
      awaySeconds: awaySeconds ?? this.awaySeconds,
      firstActivityMinute: firstActivityMinute ?? this.firstActivityMinute,
      lastActivityMinute: lastActivityMinute ?? this.lastActivityMinute,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (screenSeconds.present) {
      map['screen_seconds'] = Variable<int>(screenSeconds.value);
    }
    if (longestStretchSeconds.present) {
      map['longest_stretch_seconds'] = Variable<int>(
        longestStretchSeconds.value,
      );
    }
    if (breaksCompleted.present) {
      map['breaks_completed'] = Variable<int>(breaksCompleted.value);
    }
    if (breaksCredited.present) {
      map['breaks_credited'] = Variable<int>(breaksCredited.value);
    }
    if (breaksEscaped.present) {
      map['breaks_escaped'] = Variable<int>(breaksEscaped.value);
    }
    if (snoozes.present) {
      map['snoozes'] = Variable<int>(snoozes.value);
    }
    if (idleSeconds.present) {
      map['idle_seconds'] = Variable<int>(idleSeconds.value);
    }
    if (awaySeconds.present) {
      map['away_seconds'] = Variable<int>(awaySeconds.value);
    }
    if (firstActivityMinute.present) {
      map['first_activity_minute'] = Variable<int>(firstActivityMinute.value);
    }
    if (lastActivityMinute.present) {
      map['last_activity_minute'] = Variable<int>(lastActivityMinute.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRollupsCompanion(')
          ..write('day: $day, ')
          ..write('screenSeconds: $screenSeconds, ')
          ..write('longestStretchSeconds: $longestStretchSeconds, ')
          ..write('breaksCompleted: $breaksCompleted, ')
          ..write('breaksCredited: $breaksCredited, ')
          ..write('breaksEscaped: $breaksEscaped, ')
          ..write('snoozes: $snoozes, ')
          ..write('idleSeconds: $idleSeconds, ')
          ..write('awaySeconds: $awaySeconds, ')
          ..write('firstActivityMinute: $firstActivityMinute, ')
          ..write('lastActivityMinute: $lastActivityMinute, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseLogRowsTable extends ExerciseLogRows
    with TableInfo<$ExerciseLogRowsTable, ExerciseLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, exerciseId, completed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $ExerciseLogRowsTable createAlias(String alias) {
    return $ExerciseLogRowsTable(attachedDatabase, alias);
  }
}

class ExerciseLogRow extends DataClass implements Insertable<ExerciseLogRow> {
  final int id;
  final DateTime at;
  final String exerciseId;
  final bool completed;
  const ExerciseLogRow({
    required this.id,
    required this.at,
    required this.exerciseId,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  ExerciseLogRowsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseLogRowsCompanion(
      id: Value(id),
      at: Value(at),
      exerciseId: Value(exerciseId),
      completed: Value(completed),
    );
  }

  factory ExerciseLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseLogRow(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  ExerciseLogRow copyWith({
    int? id,
    DateTime? at,
    String? exerciseId,
    bool? completed,
  }) => ExerciseLogRow(
    id: id ?? this.id,
    at: at ?? this.at,
    exerciseId: exerciseId ?? this.exerciseId,
    completed: completed ?? this.completed,
  );
  ExerciseLogRow copyWithCompanion(ExerciseLogRowsCompanion data) {
    return ExerciseLogRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLogRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, exerciseId, completed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseLogRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.exerciseId == this.exerciseId &&
          other.completed == this.completed);
}

class ExerciseLogRowsCompanion extends UpdateCompanion<ExerciseLogRow> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> exerciseId;
  final Value<bool> completed;
  const ExerciseLogRowsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.completed = const Value.absent(),
  });
  ExerciseLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String exerciseId,
    required bool completed,
  }) : at = Value(at),
       exerciseId = Value(exerciseId),
       completed = Value(completed);
  static Insertable<ExerciseLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? exerciseId,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (completed != null) 'completed': completed,
    });
  }

  ExerciseLogRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? exerciseId,
    Value<bool>? completed,
  }) {
    return ExerciseLogRowsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      exerciseId: exerciseId ?? this.exerciseId,
      completed: completed ?? this.completed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

class $SettingRowsTable extends SettingRows
    with TableInfo<$SettingRowsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingRowsTable createAlias(String alias) {
    return $SettingRowsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingRowsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingRowsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingRowsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdviceLogRowsTable extends AdviceLogRows
    with TableInfo<$AdviceLogRowsTable, AdviceLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdviceLogRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _shownAtMeta = const VerificationMeta(
    'shownAt',
  );
  @override
  late final GeneratedColumn<DateTime> shownAt = GeneratedColumn<DateTime>(
    'shown_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, shownAt, ruleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'advice_log_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdviceLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('shown_at')) {
      context.handle(
        _shownAtMeta,
        shownAt.isAcceptableOrUnknown(data['shown_at']!, _shownAtMeta),
      );
    } else if (isInserting) {
      context.missing(_shownAtMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AdviceLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdviceLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      shownAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}shown_at'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
    );
  }

  @override
  $AdviceLogRowsTable createAlias(String alias) {
    return $AdviceLogRowsTable(attachedDatabase, alias);
  }
}

class AdviceLogRow extends DataClass implements Insertable<AdviceLogRow> {
  final int id;
  final DateTime shownAt;
  final String ruleId;
  const AdviceLogRow({
    required this.id,
    required this.shownAt,
    required this.ruleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['shown_at'] = Variable<DateTime>(shownAt);
    map['rule_id'] = Variable<String>(ruleId);
    return map;
  }

  AdviceLogRowsCompanion toCompanion(bool nullToAbsent) {
    return AdviceLogRowsCompanion(
      id: Value(id),
      shownAt: Value(shownAt),
      ruleId: Value(ruleId),
    );
  }

  factory AdviceLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdviceLogRow(
      id: serializer.fromJson<int>(json['id']),
      shownAt: serializer.fromJson<DateTime>(json['shownAt']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'shownAt': serializer.toJson<DateTime>(shownAt),
      'ruleId': serializer.toJson<String>(ruleId),
    };
  }

  AdviceLogRow copyWith({int? id, DateTime? shownAt, String? ruleId}) =>
      AdviceLogRow(
        id: id ?? this.id,
        shownAt: shownAt ?? this.shownAt,
        ruleId: ruleId ?? this.ruleId,
      );
  AdviceLogRow copyWithCompanion(AdviceLogRowsCompanion data) {
    return AdviceLogRow(
      id: data.id.present ? data.id.value : this.id,
      shownAt: data.shownAt.present ? data.shownAt.value : this.shownAt,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdviceLogRow(')
          ..write('id: $id, ')
          ..write('shownAt: $shownAt, ')
          ..write('ruleId: $ruleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, shownAt, ruleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdviceLogRow &&
          other.id == this.id &&
          other.shownAt == this.shownAt &&
          other.ruleId == this.ruleId);
}

class AdviceLogRowsCompanion extends UpdateCompanion<AdviceLogRow> {
  final Value<int> id;
  final Value<DateTime> shownAt;
  final Value<String> ruleId;
  const AdviceLogRowsCompanion({
    this.id = const Value.absent(),
    this.shownAt = const Value.absent(),
    this.ruleId = const Value.absent(),
  });
  AdviceLogRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime shownAt,
    required String ruleId,
  }) : shownAt = Value(shownAt),
       ruleId = Value(ruleId);
  static Insertable<AdviceLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? shownAt,
    Expression<String>? ruleId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shownAt != null) 'shown_at': shownAt,
      if (ruleId != null) 'rule_id': ruleId,
    });
  }

  AdviceLogRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? shownAt,
    Value<String>? ruleId,
  }) {
    return AdviceLogRowsCompanion(
      id: id ?? this.id,
      shownAt: shownAt ?? this.shownAt,
      ruleId: ruleId ?? this.ruleId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (shownAt.present) {
      map['shown_at'] = Variable<DateTime>(shownAt.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdviceLogRowsCompanion(')
          ..write('id: $id, ')
          ..write('shownAt: $shownAt, ')
          ..write('ruleId: $ruleId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActivitySlicesTable activitySlices = $ActivitySlicesTable(this);
  late final $BreakEventRowsTable breakEventRows = $BreakEventRowsTable(this);
  late final $DailyRollupsTable dailyRollups = $DailyRollupsTable(this);
  late final $ExerciseLogRowsTable exerciseLogRows = $ExerciseLogRowsTable(
    this,
  );
  late final $SettingRowsTable settingRows = $SettingRowsTable(this);
  late final $AdviceLogRowsTable adviceLogRows = $AdviceLogRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    activitySlices,
    breakEventRows,
    dailyRollups,
    exerciseLogRows,
    settingRows,
    adviceLogRows,
  ];
}

typedef $$ActivitySlicesTableCreateCompanionBuilder =
    ActivitySlicesCompanion Function({
      Value<int> id,
      required DateTime startAt,
      required DateTime endAt,
      required SliceKind kind,
    });
typedef $$ActivitySlicesTableUpdateCompanionBuilder =
    ActivitySlicesCompanion Function({
      Value<int> id,
      Value<DateTime> startAt,
      Value<DateTime> endAt,
      Value<SliceKind> kind,
    });

class $$ActivitySlicesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitySlicesTable> {
  $$ActivitySlicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SliceKind, SliceKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ActivitySlicesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitySlicesTable> {
  $$ActivitySlicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivitySlicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitySlicesTable> {
  $$ActivitySlicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SliceKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$ActivitySlicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivitySlicesTable,
          ActivitySliceRow,
          $$ActivitySlicesTableFilterComposer,
          $$ActivitySlicesTableOrderingComposer,
          $$ActivitySlicesTableAnnotationComposer,
          $$ActivitySlicesTableCreateCompanionBuilder,
          $$ActivitySlicesTableUpdateCompanionBuilder,
          (
            ActivitySliceRow,
            BaseReferences<
              _$AppDatabase,
              $ActivitySlicesTable,
              ActivitySliceRow
            >,
          ),
          ActivitySliceRow,
          PrefetchHooks Function()
        > {
  $$ActivitySlicesTableTableManager(
    _$AppDatabase db,
    $ActivitySlicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitySlicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitySlicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitySlicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<DateTime> endAt = const Value.absent(),
                Value<SliceKind> kind = const Value.absent(),
              }) => ActivitySlicesCompanion(
                id: id,
                startAt: startAt,
                endAt: endAt,
                kind: kind,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startAt,
                required DateTime endAt,
                required SliceKind kind,
              }) => ActivitySlicesCompanion.insert(
                id: id,
                startAt: startAt,
                endAt: endAt,
                kind: kind,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivitySlicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivitySlicesTable,
      ActivitySliceRow,
      $$ActivitySlicesTableFilterComposer,
      $$ActivitySlicesTableOrderingComposer,
      $$ActivitySlicesTableAnnotationComposer,
      $$ActivitySlicesTableCreateCompanionBuilder,
      $$ActivitySlicesTableUpdateCompanionBuilder,
      (
        ActivitySliceRow,
        BaseReferences<_$AppDatabase, $ActivitySlicesTable, ActivitySliceRow>,
      ),
      ActivitySliceRow,
      PrefetchHooks Function()
    >;
typedef $$BreakEventRowsTableCreateCompanionBuilder =
    BreakEventRowsCompanion Function({
      Value<int> id,
      required DateTime at,
      required BreakKind breakKind,
      required BreakAction action,
      Value<int?> valueMs,
    });
typedef $$BreakEventRowsTableUpdateCompanionBuilder =
    BreakEventRowsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<BreakKind> breakKind,
      Value<BreakAction> action,
      Value<int?> valueMs,
    });

class $$BreakEventRowsTableFilterComposer
    extends Composer<_$AppDatabase, $BreakEventRowsTable> {
  $$BreakEventRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BreakKind, BreakKind, int> get breakKind =>
      $composableBuilder(
        column: $table.breakKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<BreakAction, BreakAction, int> get action =>
      $composableBuilder(
        column: $table.action,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get valueMs => $composableBuilder(
    column: $table.valueMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BreakEventRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $BreakEventRowsTable> {
  $$BreakEventRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breakKind => $composableBuilder(
    column: $table.breakKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueMs => $composableBuilder(
    column: $table.valueMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BreakEventRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BreakEventRowsTable> {
  $$BreakEventRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BreakKind, int> get breakKind =>
      $composableBuilder(column: $table.breakKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BreakAction, int> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get valueMs =>
      $composableBuilder(column: $table.valueMs, builder: (column) => column);
}

class $$BreakEventRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BreakEventRowsTable,
          BreakEventRow,
          $$BreakEventRowsTableFilterComposer,
          $$BreakEventRowsTableOrderingComposer,
          $$BreakEventRowsTableAnnotationComposer,
          $$BreakEventRowsTableCreateCompanionBuilder,
          $$BreakEventRowsTableUpdateCompanionBuilder,
          (
            BreakEventRow,
            BaseReferences<_$AppDatabase, $BreakEventRowsTable, BreakEventRow>,
          ),
          BreakEventRow,
          PrefetchHooks Function()
        > {
  $$BreakEventRowsTableTableManager(
    _$AppDatabase db,
    $BreakEventRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BreakEventRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BreakEventRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BreakEventRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<BreakKind> breakKind = const Value.absent(),
                Value<BreakAction> action = const Value.absent(),
                Value<int?> valueMs = const Value.absent(),
              }) => BreakEventRowsCompanion(
                id: id,
                at: at,
                breakKind: breakKind,
                action: action,
                valueMs: valueMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required BreakKind breakKind,
                required BreakAction action,
                Value<int?> valueMs = const Value.absent(),
              }) => BreakEventRowsCompanion.insert(
                id: id,
                at: at,
                breakKind: breakKind,
                action: action,
                valueMs: valueMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BreakEventRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BreakEventRowsTable,
      BreakEventRow,
      $$BreakEventRowsTableFilterComposer,
      $$BreakEventRowsTableOrderingComposer,
      $$BreakEventRowsTableAnnotationComposer,
      $$BreakEventRowsTableCreateCompanionBuilder,
      $$BreakEventRowsTableUpdateCompanionBuilder,
      (
        BreakEventRow,
        BaseReferences<_$AppDatabase, $BreakEventRowsTable, BreakEventRow>,
      ),
      BreakEventRow,
      PrefetchHooks Function()
    >;
typedef $$DailyRollupsTableCreateCompanionBuilder =
    DailyRollupsCompanion Function({
      required DateTime day,
      required int screenSeconds,
      required int longestStretchSeconds,
      required int breaksCompleted,
      required int breaksCredited,
      required int breaksEscaped,
      required int snoozes,
      Value<int> idleSeconds,
      Value<int> awaySeconds,
      Value<int?> firstActivityMinute,
      Value<int?> lastActivityMinute,
      Value<int> rowid,
    });
typedef $$DailyRollupsTableUpdateCompanionBuilder =
    DailyRollupsCompanion Function({
      Value<DateTime> day,
      Value<int> screenSeconds,
      Value<int> longestStretchSeconds,
      Value<int> breaksCompleted,
      Value<int> breaksCredited,
      Value<int> breaksEscaped,
      Value<int> snoozes,
      Value<int> idleSeconds,
      Value<int> awaySeconds,
      Value<int?> firstActivityMinute,
      Value<int?> lastActivityMinute,
      Value<int> rowid,
    });

class $$DailyRollupsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get screenSeconds => $composableBuilder(
    column: $table.screenSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStretchSeconds => $composableBuilder(
    column: $table.longestStretchSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breaksCompleted => $composableBuilder(
    column: $table.breaksCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breaksCredited => $composableBuilder(
    column: $table.breaksCredited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get breaksEscaped => $composableBuilder(
    column: $table.breaksEscaped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozes => $composableBuilder(
    column: $table.snoozes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get idleSeconds => $composableBuilder(
    column: $table.idleSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awaySeconds => $composableBuilder(
    column: $table.awaySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstActivityMinute => $composableBuilder(
    column: $table.firstActivityMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastActivityMinute => $composableBuilder(
    column: $table.lastActivityMinute,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyRollupsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get screenSeconds => $composableBuilder(
    column: $table.screenSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStretchSeconds => $composableBuilder(
    column: $table.longestStretchSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breaksCompleted => $composableBuilder(
    column: $table.breaksCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breaksCredited => $composableBuilder(
    column: $table.breaksCredited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get breaksEscaped => $composableBuilder(
    column: $table.breaksEscaped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozes => $composableBuilder(
    column: $table.snoozes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get idleSeconds => $composableBuilder(
    column: $table.idleSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awaySeconds => $composableBuilder(
    column: $table.awaySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstActivityMinute => $composableBuilder(
    column: $table.firstActivityMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastActivityMinute => $composableBuilder(
    column: $table.lastActivityMinute,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyRollupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRollupsTable> {
  $$DailyRollupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get screenSeconds => $composableBuilder(
    column: $table.screenSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStretchSeconds => $composableBuilder(
    column: $table.longestStretchSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breaksCompleted => $composableBuilder(
    column: $table.breaksCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breaksCredited => $composableBuilder(
    column: $table.breaksCredited,
    builder: (column) => column,
  );

  GeneratedColumn<int> get breaksEscaped => $composableBuilder(
    column: $table.breaksEscaped,
    builder: (column) => column,
  );

  GeneratedColumn<int> get snoozes =>
      $composableBuilder(column: $table.snoozes, builder: (column) => column);

  GeneratedColumn<int> get idleSeconds => $composableBuilder(
    column: $table.idleSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awaySeconds => $composableBuilder(
    column: $table.awaySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstActivityMinute => $composableBuilder(
    column: $table.firstActivityMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastActivityMinute => $composableBuilder(
    column: $table.lastActivityMinute,
    builder: (column) => column,
  );
}

class $$DailyRollupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyRollupsTable,
          DailyRollup,
          $$DailyRollupsTableFilterComposer,
          $$DailyRollupsTableOrderingComposer,
          $$DailyRollupsTableAnnotationComposer,
          $$DailyRollupsTableCreateCompanionBuilder,
          $$DailyRollupsTableUpdateCompanionBuilder,
          (
            DailyRollup,
            BaseReferences<_$AppDatabase, $DailyRollupsTable, DailyRollup>,
          ),
          DailyRollup,
          PrefetchHooks Function()
        > {
  $$DailyRollupsTableTableManager(_$AppDatabase db, $DailyRollupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRollupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRollupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRollupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<int> screenSeconds = const Value.absent(),
                Value<int> longestStretchSeconds = const Value.absent(),
                Value<int> breaksCompleted = const Value.absent(),
                Value<int> breaksCredited = const Value.absent(),
                Value<int> breaksEscaped = const Value.absent(),
                Value<int> snoozes = const Value.absent(),
                Value<int> idleSeconds = const Value.absent(),
                Value<int> awaySeconds = const Value.absent(),
                Value<int?> firstActivityMinute = const Value.absent(),
                Value<int?> lastActivityMinute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRollupsCompanion(
                day: day,
                screenSeconds: screenSeconds,
                longestStretchSeconds: longestStretchSeconds,
                breaksCompleted: breaksCompleted,
                breaksCredited: breaksCredited,
                breaksEscaped: breaksEscaped,
                snoozes: snoozes,
                idleSeconds: idleSeconds,
                awaySeconds: awaySeconds,
                firstActivityMinute: firstActivityMinute,
                lastActivityMinute: lastActivityMinute,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required int screenSeconds,
                required int longestStretchSeconds,
                required int breaksCompleted,
                required int breaksCredited,
                required int breaksEscaped,
                required int snoozes,
                Value<int> idleSeconds = const Value.absent(),
                Value<int> awaySeconds = const Value.absent(),
                Value<int?> firstActivityMinute = const Value.absent(),
                Value<int?> lastActivityMinute = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRollupsCompanion.insert(
                day: day,
                screenSeconds: screenSeconds,
                longestStretchSeconds: longestStretchSeconds,
                breaksCompleted: breaksCompleted,
                breaksCredited: breaksCredited,
                breaksEscaped: breaksEscaped,
                snoozes: snoozes,
                idleSeconds: idleSeconds,
                awaySeconds: awaySeconds,
                firstActivityMinute: firstActivityMinute,
                lastActivityMinute: lastActivityMinute,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyRollupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyRollupsTable,
      DailyRollup,
      $$DailyRollupsTableFilterComposer,
      $$DailyRollupsTableOrderingComposer,
      $$DailyRollupsTableAnnotationComposer,
      $$DailyRollupsTableCreateCompanionBuilder,
      $$DailyRollupsTableUpdateCompanionBuilder,
      (
        DailyRollup,
        BaseReferences<_$AppDatabase, $DailyRollupsTable, DailyRollup>,
      ),
      DailyRollup,
      PrefetchHooks Function()
    >;
typedef $$ExerciseLogRowsTableCreateCompanionBuilder =
    ExerciseLogRowsCompanion Function({
      Value<int> id,
      required DateTime at,
      required String exerciseId,
      required bool completed,
    });
typedef $$ExerciseLogRowsTableUpdateCompanionBuilder =
    ExerciseLogRowsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<String> exerciseId,
      Value<bool> completed,
    });

class $$ExerciseLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseLogRowsTable> {
  $$ExerciseLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseLogRowsTable> {
  $$ExerciseLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseLogRowsTable> {
  $$ExerciseLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$ExerciseLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseLogRowsTable,
          ExerciseLogRow,
          $$ExerciseLogRowsTableFilterComposer,
          $$ExerciseLogRowsTableOrderingComposer,
          $$ExerciseLogRowsTableAnnotationComposer,
          $$ExerciseLogRowsTableCreateCompanionBuilder,
          $$ExerciseLogRowsTableUpdateCompanionBuilder,
          (
            ExerciseLogRow,
            BaseReferences<
              _$AppDatabase,
              $ExerciseLogRowsTable,
              ExerciseLogRow
            >,
          ),
          ExerciseLogRow,
          PrefetchHooks Function()
        > {
  $$ExerciseLogRowsTableTableManager(
    _$AppDatabase db,
    $ExerciseLogRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => ExerciseLogRowsCompanion(
                id: id,
                at: at,
                exerciseId: exerciseId,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String exerciseId,
                required bool completed,
              }) => ExerciseLogRowsCompanion.insert(
                id: id,
                at: at,
                exerciseId: exerciseId,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseLogRowsTable,
      ExerciseLogRow,
      $$ExerciseLogRowsTableFilterComposer,
      $$ExerciseLogRowsTableOrderingComposer,
      $$ExerciseLogRowsTableAnnotationComposer,
      $$ExerciseLogRowsTableCreateCompanionBuilder,
      $$ExerciseLogRowsTableUpdateCompanionBuilder,
      (
        ExerciseLogRow,
        BaseReferences<_$AppDatabase, $ExerciseLogRowsTable, ExerciseLogRow>,
      ),
      ExerciseLogRow,
      PrefetchHooks Function()
    >;
typedef $$SettingRowsTableCreateCompanionBuilder =
    SettingRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingRowsTableUpdateCompanionBuilder =
    SettingRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingRowsTable> {
  $$SettingRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingRowsTable,
          SettingRow,
          $$SettingRowsTableFilterComposer,
          $$SettingRowsTableOrderingComposer,
          $$SettingRowsTableAnnotationComposer,
          $$SettingRowsTableCreateCompanionBuilder,
          $$SettingRowsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingRowsTableTableManager(_$AppDatabase db, $SettingRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingRowsTable,
      SettingRow,
      $$SettingRowsTableFilterComposer,
      $$SettingRowsTableOrderingComposer,
      $$SettingRowsTableAnnotationComposer,
      $$SettingRowsTableCreateCompanionBuilder,
      $$SettingRowsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingRowsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$AdviceLogRowsTableCreateCompanionBuilder =
    AdviceLogRowsCompanion Function({
      Value<int> id,
      required DateTime shownAt,
      required String ruleId,
    });
typedef $$AdviceLogRowsTableUpdateCompanionBuilder =
    AdviceLogRowsCompanion Function({
      Value<int> id,
      Value<DateTime> shownAt,
      Value<String> ruleId,
    });

class $$AdviceLogRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AdviceLogRowsTable> {
  $$AdviceLogRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get shownAt => $composableBuilder(
    column: $table.shownAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdviceLogRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdviceLogRowsTable> {
  $$AdviceLogRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get shownAt => $composableBuilder(
    column: $table.shownAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdviceLogRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdviceLogRowsTable> {
  $$AdviceLogRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get shownAt =>
      $composableBuilder(column: $table.shownAt, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);
}

class $$AdviceLogRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdviceLogRowsTable,
          AdviceLogRow,
          $$AdviceLogRowsTableFilterComposer,
          $$AdviceLogRowsTableOrderingComposer,
          $$AdviceLogRowsTableAnnotationComposer,
          $$AdviceLogRowsTableCreateCompanionBuilder,
          $$AdviceLogRowsTableUpdateCompanionBuilder,
          (
            AdviceLogRow,
            BaseReferences<_$AppDatabase, $AdviceLogRowsTable, AdviceLogRow>,
          ),
          AdviceLogRow,
          PrefetchHooks Function()
        > {
  $$AdviceLogRowsTableTableManager(_$AppDatabase db, $AdviceLogRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdviceLogRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdviceLogRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdviceLogRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> shownAt = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
              }) => AdviceLogRowsCompanion(
                id: id,
                shownAt: shownAt,
                ruleId: ruleId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime shownAt,
                required String ruleId,
              }) => AdviceLogRowsCompanion.insert(
                id: id,
                shownAt: shownAt,
                ruleId: ruleId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdviceLogRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdviceLogRowsTable,
      AdviceLogRow,
      $$AdviceLogRowsTableFilterComposer,
      $$AdviceLogRowsTableOrderingComposer,
      $$AdviceLogRowsTableAnnotationComposer,
      $$AdviceLogRowsTableCreateCompanionBuilder,
      $$AdviceLogRowsTableUpdateCompanionBuilder,
      (
        AdviceLogRow,
        BaseReferences<_$AppDatabase, $AdviceLogRowsTable, AdviceLogRow>,
      ),
      AdviceLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActivitySlicesTableTableManager get activitySlices =>
      $$ActivitySlicesTableTableManager(_db, _db.activitySlices);
  $$BreakEventRowsTableTableManager get breakEventRows =>
      $$BreakEventRowsTableTableManager(_db, _db.breakEventRows);
  $$DailyRollupsTableTableManager get dailyRollups =>
      $$DailyRollupsTableTableManager(_db, _db.dailyRollups);
  $$ExerciseLogRowsTableTableManager get exerciseLogRows =>
      $$ExerciseLogRowsTableTableManager(_db, _db.exerciseLogRows);
  $$SettingRowsTableTableManager get settingRows =>
      $$SettingRowsTableTableManager(_db, _db.settingRows);
  $$AdviceLogRowsTableTableManager get adviceLogRows =>
      $$AdviceLogRowsTableTableManager(_db, _db.adviceLogRows);
}
