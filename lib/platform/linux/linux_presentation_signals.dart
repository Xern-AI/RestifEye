// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:dbus/dbus.dart';

import '../../app/brand.dart';
import '../interfaces/presentation_signals.dart';

/// "Don't interrupt me" detection from idle inhibitors, the one signal that
/// works on Wayland without window snooping.
///
/// Two independent sources, unioned because they hold different clients:
/// - **gnome-session** — where `org.freedesktop.ScreenSaver.Inhibit` calls
///   land on GNOME. This is what Firefox, Chrome, VLC and mpv take when a
///   video goes fullscreen, and what presentation tools take throughout.
/// - **logind** — desktop-independent inhibitors, so the feature degrades to
///   something useful on KDE, wlroots compositors and bare sessions.
///
/// Each source is disabled permanently the first time it proves absent, so a
/// non-GNOME box does not pay for a failing call every few seconds.
class LinuxPresentationSignals implements PresentationSignals {
  LinuxPresentationSignals({required this._session, required this._system});

  /// gnome-session's INHIBIT_IDLE bit.
  static const _inhibitIdle = 8;

  final DBusClient _session;
  final DBusClient _system;
  bool _gnomeAvailable = true;
  bool _logindAvailable = true;

  @override
  Future<PresentationState> sample() async {
    final gnome = await _gnomeSession();
    if (gnome.active) return gnome;
    return _logind();
  }

  Future<PresentationState> _gnomeSession() async {
    if (!_gnomeAvailable) return PresentationState.idle;
    final manager = DBusRemoteObject(
      _session,
      name: 'org.gnome.SessionManager',
      path: DBusObjectPath('/org/gnome/SessionManager'),
    );
    try {
      final reply = await manager.callMethod(
        'org.gnome.SessionManager',
        'IsInhibited',
        [const DBusUint32(_inhibitIdle)],
        replySignature: DBusSignature('b'),
      );
      if (!(reply.returnValues.first as DBusBoolean).value) {
        return PresentationState.idle;
      }
      return PresentationState(active: true, byApp: await _gnomeInhibitorApp());
    } on DBusServiceUnknownException {
      _gnomeAvailable = false; // not a GNOME session
      return PresentationState.idle;
    } on Exception {
      return PresentationState.idle; // transient: fail open, keep breaks alive
    }
  }

  /// Best-effort name of the app holding the idle inhibitor. Purely for the
  /// UI copy, so every failure here is silent.
  Future<String?> _gnomeInhibitorApp() async {
    try {
      final manager = DBusRemoteObject(
        _session,
        name: 'org.gnome.SessionManager',
        path: DBusObjectPath('/org/gnome/SessionManager'),
      );
      final reply = await manager.callMethod(
        'org.gnome.SessionManager',
        'GetInhibitors',
        const [],
        replySignature: DBusSignature('ao'),
      );
      final paths = (reply.returnValues.first as DBusArray).children
          .cast<DBusObjectPath>();
      for (final path in paths) {
        final inhibitor = DBusRemoteObject(
          _session,
          name: 'org.gnome.SessionManager',
          path: path,
        );
        final flags = await inhibitor.callMethod(
          'org.gnome.SessionManager.Inhibitor',
          'GetFlags',
          const [],
          replySignature: DBusSignature('u'),
        );
        if ((flags.returnValues.first as DBusUint32).value & _inhibitIdle ==
            0) {
          continue;
        }
        final appId = await inhibitor.callMethod(
          'org.gnome.SessionManager.Inhibitor',
          'GetAppId',
          const [],
          replySignature: DBusSignature('s'),
        );
        final name = (appId.returnValues.first as DBusString).value.trim();
        if (name.isNotEmpty && !_isOurs(name)) return name;
      }
    } on Exception {
      // Name is a nicety; the pause works without it.
    }
    return null;
  }

  Future<PresentationState> _logind() async {
    if (!_logindAvailable) return PresentationState.idle;
    final manager = DBusRemoteObject(
      _system,
      name: 'org.freedesktop.login1',
      path: DBusObjectPath('/org/freedesktop/login1'),
    );
    try {
      final reply = await manager.callMethod(
        'org.freedesktop.login1.Manager',
        'ListInhibitors',
        const [],
        replySignature: DBusSignature('a(ssssuu)'),
      );
      final rows = (reply.returnValues.first as DBusArray).children
          .cast<DBusStruct>();
      for (final row in rows) {
        final fields = row.children.toList();
        final what = (fields[0] as DBusString).value;
        final who = (fields[1] as DBusString).value.trim();
        final mode = (fields[3] as DBusString).value;
        // `what` is colon-separated ("sleep:idle"); only a *blocking* idle
        // inhibitor means "keep the screen alive for me". A `delay` one is
        // about shutdown ordering and says nothing about what's on screen.
        final blocksIdle = mode == 'block' && what.split(':').contains('idle');
        if (blocksIdle && !_isOurs(who)) {
          return PresentationState(
            active: true,
            byApp: who.isEmpty ? null : who,
          );
        }
      }
      return PresentationState.idle;
    } on DBusServiceUnknownException {
      _logindAvailable = false; // no systemd-logind on this box
      return PresentationState.idle;
    } on Exception {
      return PresentationState.idle;
    }
  }

  /// Never let our own process (or a stale inhibitor of ours) pause us.
  bool _isOurs(String name) {
    final lower = name.toLowerCase();
    return lower == Brand.appId.toLowerCase() ||
        lower == Brand.appName.toLowerCase();
  }
}
