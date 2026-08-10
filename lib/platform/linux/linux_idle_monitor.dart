// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:dbus/dbus.dart';

import '../interfaces/idle_monitor.dart';

/// Idle time via D-Bus. Tries GNOME Mutter first (Tier 1: Fedora/GNOME,
/// works on Wayland and X11), then the freedesktop ScreenSaver interface
/// (KDE and others). The first backend that answers is kept.
///
/// wlroots compositors expose neither — planned via ext-idle-notify-v1.
class LinuxIdleMonitor implements IdleMonitor {
  LinuxIdleMonitor(this._bus);

  final DBusClient _bus;
  _Backend? _backend;
  bool _probed = false;

  @override
  Future<Duration> currentIdle() async {
    if (!_probed) await _probe();
    try {
      return switch (_backend) {
        _Backend.mutter => await _mutterIdle(),
        _Backend.screenSaver => await _screenSaverIdle(),
        null => Duration.zero,
      };
    } on DBusMethodResponseException {
      return Duration.zero; // transient failure: treat as active, keep going
    }
  }

  Future<void> _probe() async {
    _probed = true;
    try {
      await _mutterIdle();
      _backend = _Backend.mutter;
      return;
    } on Exception {
      // Not GNOME — try the freedesktop interface.
    }
    try {
      await _screenSaverIdle();
      _backend = _Backend.screenSaver;
    } on Exception {
      _backend = null; // No idle source; engine still runs on wall timers.
    }
  }

  Future<Duration> _mutterIdle() async {
    final object = DBusRemoteObject(
      _bus,
      name: 'org.gnome.Mutter.IdleMonitor',
      path: DBusObjectPath('/org/gnome/Mutter/IdleMonitor/Core'),
    );
    final reply = await object.callMethod(
      'org.gnome.Mutter.IdleMonitor',
      'GetIdletime',
      [],
      replySignature: DBusSignature('t'),
    );
    return Duration(milliseconds: reply.returnValues[0].asUint64());
  }

  Future<Duration> _screenSaverIdle() async {
    final object = DBusRemoteObject(
      _bus,
      name: 'org.freedesktop.ScreenSaver',
      path: DBusObjectPath('/org/freedesktop/ScreenSaver'),
    );
    final reply = await object.callMethod(
      'org.freedesktop.ScreenSaver',
      'GetSessionIdleTime',
      [],
      replySignature: DBusSignature('u'),
    );
    return Duration(seconds: reply.returnValues[0].asUint32());
  }

  @override
  Future<void> dispose() async {
    // The bus is shared and closed by its owner.
  }
}

enum _Backend { mutter, screenSaver }
