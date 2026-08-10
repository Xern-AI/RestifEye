// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dbus/dbus.dart';

import '../interfaces/session_signals.dart';

/// Lock/suspend via D-Bus signals:
/// - GNOME and freedesktop ScreenSaver `ActiveChanged` (session bus)
/// - logind `PrepareForSleep` (system bus) for suspend/resume
class LinuxSessionSignals implements SessionSignals {
  LinuxSessionSignals({required this._session, required this._system}) {
    _subscribe();
  }

  final DBusClient _session;
  final DBusClient _system;
  final _controller = StreamController<bool>.broadcast();
  final List<StreamSubscription<DBusSignal>> _subs = [];

  bool _saverActive = false;
  bool _sleeping = false;

  @override
  Stream<bool> get away => _controller.stream;

  void _subscribe() {
    for (final sender in [
      'org.gnome.ScreenSaver',
      'org.freedesktop.ScreenSaver',
    ]) {
      final stream = DBusSignalStream(
        _session,
        sender: sender,
        interface: sender,
        name: 'ActiveChanged',
        signature: DBusSignature('b'),
      );
      _subs.add(
        stream.listen((signal) {
          _saverActive = signal.values[0].asBoolean();
          _publish();
        }, onError: (Object _) {}),
      );
    }

    final sleep = DBusSignalStream(
      _system,
      sender: 'org.freedesktop.login1',
      interface: 'org.freedesktop.login1.Manager',
      name: 'PrepareForSleep',
      signature: DBusSignature('b'),
    );
    _subs.add(
      sleep.listen((signal) {
        _sleeping = signal.values[0].asBoolean();
        _publish();
      }, onError: (Object _) {}),
    );
  }

  void _publish() {
    if (!_controller.isClosed) _controller.add(_saverActive || _sleeping);
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _controller.close();
  }
}
