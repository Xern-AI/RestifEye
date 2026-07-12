import 'dart:convert';

import '../core/engine/snapshot.dart';
import '../core/models/break_config.dart';
import 'database.dart';

/// Typed access to the key-value settings store.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _configKey = 'break_config';
  static const _snapshotKey = 'engine_snapshot';

  /// App-level flags (also see [getFlag]/[setFlag]).
  static const flagOnboardingDone = 'onboarding_done';
  static const flagUpdateCheck = 'update_check_enabled';
  static const flagAutostart = 'autostart_enabled';

  Future<BreakConfig> loadConfig() async {
    final raw = await _read(_configKey);
    if (raw == null) return const BreakConfig();
    try {
      return BreakConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return const BreakConfig(); // corrupt row → safe defaults
    }
  }

  Future<void> saveConfig(BreakConfig config) =>
      _write(_configKey, jsonEncode(config.toJson()));

  Future<EngineSnapshot?> loadSnapshot() async {
    final raw = await _read(_snapshotKey);
    if (raw == null) return null;
    try {
      return EngineSnapshot.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveSnapshot(EngineSnapshot snapshot) =>
      _write(_snapshotKey, jsonEncode(snapshot.toJson()));

  Future<bool> getFlag(String key, {required bool fallback}) async {
    final raw = await _read('flag_$key');
    return raw == null ? fallback : raw == 'true';
  }

  Future<void> setFlag(String key, bool value) =>
      _write('flag_$key', value.toString());

  static const _optOutsKey = 'exercise_optouts';

  Future<Set<String>> loadExerciseOptOuts() async {
    final raw = await _read(_optOutsKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).whereType<String>().toSet();
    } on FormatException {
      return {};
    }
  }

  Future<void> saveExerciseOptOuts(Set<String> ids) =>
      _write(_optOutsKey, jsonEncode(ids.toList()..sort()));

  Future<String?> _read(String key) async {
    final row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> _write(String key, String value) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(
        SettingRowsCompanion.insert(key: key, value: value),
      );
}
