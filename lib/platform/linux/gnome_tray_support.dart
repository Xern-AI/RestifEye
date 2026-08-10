// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:dbus/dbus.dart';

import '../interfaces/tray_support.dart';

/// Detects why the tray icon is missing on GNOME, and fixes it on request.
///
/// The tray icon lives in the top-right of the shell, next to battery and
/// wi-fi. GNOME removed the status area in 3.26 and never replaced it: the
/// only way in is a shell extension that hosts StatusNotifierItems. So a
/// perfectly correct SNI implementation (ours) registers itself and is drawn
/// by nobody, which is exactly what happened in the field.
///
/// GNOME does expose `org.gnome.Shell.Extensions` on the session bus, so we
/// can read the extension's state and — on an explicit click, never silently —
/// switch it on. No terminal, no logout.
class GnomeTraySupport implements TrayHostSupport {
  GnomeTraySupport(this._bus);

  static const uuid = 'appindicatorsupport@rgcjonas.gmail.com';

  /// Fallback label when the shell cannot tell us the extension's own name.
  static const extensionName = 'AppIndicator and KStatusNotifierItem Support';
  static const _watcher = 'org.kde.StatusNotifierWatcher';
  static const _shell = 'org.gnome.Shell.Extensions';
  static const _shellPath = '/org/gnome/Shell/Extensions';

  final DBusClient _bus;

  DBusRemoteObject get _extensions =>
      DBusRemoteObject(_bus, name: _shell, path: DBusObjectPath(_shellPath));

  @override
  Future<TraySupport> check() async {
    // A host is a host: on KDE, XFCE, Cinnamon and MATE this is true natively
    // and there is nothing to fix.
    if (await _hostRunning()) return const TraySupport(TrayState.working);

    final info = await _extensionInfo();
    if (info == null) return const TraySupport(TrayState.unavailable);

    // GNOME answers with an empty dict for an extension it has never seen.
    if (info.isEmpty) {
      return const TraySupport(
        TrayState.extensionMissing,
        extensionName: extensionName,
      );
    }
    return TraySupport(
      TrayState.extensionDisabled,
      extensionName: info['name']?.asString() ?? extensionName,
    );
  }

  @override
  Future<TraySupport> enable() async {
    try {
      final info = await _extensionInfo();
      if (info == null) return const TraySupport(TrayState.unavailable);

      if (info.isEmpty) {
        // Not installed. GNOME raises its own consent dialog for this.
        await _extensions.callMethod(_shell, 'InstallRemoteExtension', [
          const DBusString(uuid),
        ], replySignature: DBusSignature('s'));
      } else {
        await _extensions.callMethod(_shell, 'EnableExtension', [
          const DBusString(uuid),
        ], replySignature: DBusSignature('b'));
      }
    } on DBusMethodResponseException {
      return const TraySupport(TrayState.unavailable);
    }
    // Report what actually happened rather than assuming success: the user
    // can decline GNOME's install prompt.
    return check();
  }

  Future<bool> _hostRunning() async {
    try {
      final dbus = DBusRemoteObject(
        _bus,
        name: 'org.freedesktop.DBus',
        path: DBusObjectPath('/org/freedesktop/DBus'),
      );
      final reply = await dbus.callMethod(
        'org.freedesktop.DBus',
        'NameHasOwner',
        [const DBusString(_watcher)],
        replySignature: DBusSignature('b'),
      );
      return reply.returnValues[0].asBoolean();
    } on DBusMethodResponseException {
      return false;
    }
  }

  /// Extension metadata, `{}` when GNOME knows nothing about it (not
  /// installed), or null when this is not a GNOME session at all.
  Future<Map<String, DBusValue>?> _extensionInfo() async {
    try {
      final reply = await _extensions.callMethod(_shell, 'GetExtensionInfo', [
        const DBusString(uuid),
      ], replySignature: DBusSignature('a{sv}'));
      return reply.returnValues[0].asStringVariantDict();
    } on DBusMethodResponseException {
      return null; // no org.gnome.Shell.Extensions → not GNOME
    }
  }
}
