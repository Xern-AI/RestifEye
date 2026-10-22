// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:win32/win32.dart' show WindowsException;
import 'package:win32_registry/win32_registry.dart';

/// The few `HKEY_CURRENT_USER` operations the Windows adapters need, behind
/// an interface so their logic can be tested without Windows.
///
/// Reads answer null or empty for a key or value that does not exist: on a
/// fresh account most of these keys are simply absent, and absent is a normal
/// answer, not an error.
abstract interface class UserRegistry {
  String? readString(String path, String name);
  int? readInt(String path, String name);
  Uint8List? readBinary(String path, String name);
  List<String> subkeys(String path);
  void writeString(String path, String name, String value);
  void writeBinary(String path, String name, Uint8List value);
  void deleteValue(String path, String name);
}

/// The real `HKEY_CURRENT_USER`.
class Win32UserRegistry implements UserRegistry {
  const Win32UserRegistry();

  /// `ERROR_FILE_NOT_FOUND` as an HRESULT, compared unsigned.
  static bool _isNotFound(WindowsException e) =>
      (e.hr & 0xFFFFFFFF) == 0x80070002;

  T? _withKey<T>(String path, T? Function(RegistryKey key) read) {
    final RegistryKey key;
    try {
      key = CURRENT_USER.open(path);
    } on WindowsException catch (e) {
      if (_isNotFound(e)) return null;
      rethrow;
    }
    try {
      return read(key);
    } finally {
      key.close();
    }
  }

  @override
  String? readString(String path, String name) =>
      _withKey(path, (k) => k.getString(name));

  @override
  int? readInt(String path, String name) =>
      _withKey(path, (k) => k.getInt(name));

  @override
  Uint8List? readBinary(String path, String name) =>
      _withKey(path, (k) => k.getBinary(name));

  @override
  List<String> subkeys(String path) => _withKey(path, (k) => k.keys) ?? [];

  @override
  void writeString(String path, String name, String value) =>
      _write(path, name, StringValue(value));

  @override
  void writeBinary(String path, String name, Uint8List value) =>
      _write(path, name, BinaryValue(value));

  void _write(String path, String name, RegistryValue value) {
    final key = CURRENT_USER.create(path);
    try {
      key.setValue(name, value);
    } finally {
      key.close();
    }
  }

  @override
  void deleteValue(String path, String name) {
    final RegistryKey key;
    try {
      key = CURRENT_USER.open(
        path,
        config: const RegistryOpenConfig(access: RegistryAccess.readWrite),
      );
    } on WindowsException catch (e) {
      if (_isNotFound(e)) return;
      rethrow;
    }
    try {
      key.removeValue(name);
    } on WindowsException catch (e) {
      if (!_isNotFound(e)) rethrow;
    } finally {
      key.close();
    }
  }
}
