// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// The `ProductVersion` string Flutter compiles into the executable's
/// version resource from pubspec (e.g. `0.2.0+13`), or null if unreadable.
///
/// Reads the US-English, Windows-1252 block (`040904e4`) that the Flutter
/// runner template's `Runner.rc` declares — the same source `package_info_plus`
/// uses on Windows.
String? exeProductVersion(String executable) => using((arena) {
  final path = arena.pcwstr(executable);
  final size = GetFileVersionInfoSize(path, null).value;
  if (size <= 0) return null;
  final block = arena<Uint8>(size);
  if (!GetFileVersionInfo(path, size, block).value) return null;

  final value = arena<Pointer>();
  final length = arena<Uint32>();
  final found = VerQueryValue(
    block,
    arena.pcwstr(r'\StringFileInfo\040904e4\ProductVersion'),
    value,
    length,
  );
  if (!found || length.value == 0) return null;
  return value.value.cast<Utf16>().toDartString();
});
