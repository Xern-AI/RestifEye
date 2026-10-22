// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../interfaces/app_log.dart';
import '../interfaces/idle_monitor.dart';

/// Idle time from `GetLastInputInfo`: the tick of the last keyboard or mouse
/// input anywhere in this session.
class WindowsIdleMonitor implements IdleMonitor {
  WindowsIdleMonitor({required this.log});

  final AppLog log;
  bool _reported = false;

  /// Throws when Windows cannot answer, so startup can log it.
  void probe() => _read();

  @override
  Future<Duration> currentIdle() async {
    try {
      return _read();
    } on Object catch (e) {
      if (!_reported) log.failure('idle', e);
      _reported = true;
      return Duration.zero;
    }
  }

  Duration _read() => using((arena) {
    final info = arena<LASTINPUTINFO>()..ref.cbSize = sizeOf<LASTINPUTINFO>();
    if (!GetLastInputInfo(info)) {
      throw StateError('GetLastInputInfo failed');
    }
    return idleFromTicks(now: GetTickCount(), lastInput: info.ref.dwTime);
  });

  @override
  Future<void> dispose() async {}
}

/// Both ticks are 32-bit milliseconds that wrap every 49.7 days, so the
/// difference is taken modulo 2^32: a wrap between the two readings must not
/// turn into a negative or enormous idle time.
Duration idleFromTicks({required int now, required int lastInput}) =>
    Duration(milliseconds: (now - lastInput) & 0xFFFFFFFF);
