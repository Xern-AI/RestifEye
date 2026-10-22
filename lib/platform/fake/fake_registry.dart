// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../windows/user_registry.dart';

/// An in-memory `HKEY_CURRENT_USER` for tests. Paths are case-insensitive,
/// as in the real registry; a key exists once any value or subkey is under it.
class FakeUserRegistry implements UserRegistry {
  final Map<String, Map<String, Object>> _keys = {};

  /// Normalized path to the spelling it was first written with.
  final Map<String, String> _spelling = {};

  static String _norm(String path) => path.toLowerCase();

  void set(String path, String name, Object value) {
    _spelling.putIfAbsent(_norm(path), () => path);
    _keys.putIfAbsent(_norm(path), () => {})[name] = value;
  }

  Object? valueAt(String path, String name) => _keys[_norm(path)]?[name];

  @override
  String? readString(String path, String name) {
    final v = valueAt(path, name);
    return v is String ? v : null;
  }

  @override
  int? readInt(String path, String name) {
    final v = valueAt(path, name);
    return v is int ? v : null;
  }

  @override
  Uint8List? readBinary(String path, String name) {
    final v = valueAt(path, name);
    return v is Uint8List ? v : null;
  }

  @override
  List<String> subkeys(String path) {
    final prefix = '${_norm(path)}\\';
    final names = <String>{};
    for (final key in _keys.keys) {
      if (key.startsWith(prefix)) {
        names.add(_spelling[key]!.substring(prefix.length));
      }
    }
    return {for (final n in names) n.split('\\').first}.toList();
  }

  @override
  void writeString(String path, String name, String value) =>
      set(path, name, value);

  @override
  void writeBinary(String path, String name, Uint8List value) =>
      set(path, name, value);

  @override
  void deleteValue(String path, String name) =>
      _keys[_norm(path)]?.remove(name);
}
