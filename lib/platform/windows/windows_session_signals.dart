// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../interfaces/app_log.dart';
import '../interfaces/session_signals.dart';
import 'windows_runner.dart';

/// Lock, unlock, sleep and wake, from the runner's window procedure
/// (`WM_WTSSESSION_CHANGE` and `WM_POWERBROADCAST`).
class WindowsSessionSignals implements SessionSignals {
  WindowsSessionSignals(WindowsRunner runner, {AppLog log = const NoAppLog()}) {
    _sub = runner.sessionEvents.listen((event) {
      log.info('session $event');
      if (!_controller.isClosed) _controller.add(_state.apply(event));
    });
  }

  final _controller = StreamController<bool>.broadcast();
  final _state = SessionAwayState();
  late final StreamSubscription<String> _sub;

  @override
  Stream<bool> get away => _controller.stream;

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _controller.close();
  }
}

/// Folds raw session events into "away", the same union of lock and sleep
/// the Linux adapter publishes.
///
/// Kept as two flags rather than one because the events overlap: a laptop
/// usually locks before it sleeps and wakes still locked, so `resume` alone
/// must not report the user as back.
class SessionAwayState {
  bool _locked = false;
  bool _asleep = false;

  bool get away => _locked || _asleep;

  /// Applies one event and returns the resulting away state. Unknown events
  /// change nothing.
  bool apply(String event) {
    switch (event) {
      case 'lock':
        _locked = true;
      case 'unlock':
        _locked = false;
      case 'suspend':
        _asleep = true;
      case 'resume':
        _asleep = false;
    }
    return away;
  }
}
