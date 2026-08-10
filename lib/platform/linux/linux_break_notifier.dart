// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dbus/dbus.dart';

import '../../app/brand.dart';
import '../../core/models/break_kind.dart';
import '../interfaces/break_notifier.dart';

/// Warning notifications via org.freedesktop.Notifications — no plugin
/// needed, works on every major desktop.
///
/// Two invariants this class exists to keep:
///
///  * **Exactly one live notification.** Re-warns replace the current one in
///    place via `replaces_id`, so a deferral never stacks up banners.
///  * **A new cycle always raises a new banner.** `replaces_id` is only ever
///    a *live* id. Passing an id the daemon has already destroyed makes it
///    write into a dead slot instead of notifying — which silently swallowed
///    the warning and is why breaks sometimes arrived with no heads-up at all.
///
/// Every D-Bus call goes through one queue: `Notify` and `CloseNotification`
/// used to be fired and forgotten, so a dismiss could overtake the show whose
/// reply carried the id to dismiss, orphaning the notification permanently.
class LinuxBreakNotifier implements BreakNotifier {
  LinuxBreakNotifier(this._bus) {
    _actionSub =
        DBusSignalStream(
          _bus,
          sender: _dest,
          interface: _iface,
          name: 'ActionInvoked',
          signature: DBusSignature('us'),
        ).listen((signal) {
          if (signal.values[0].asUint32() != _activeId) return;
          switch (signal.values[1].asString()) {
            case _actionSnooze:
              _actions.add(WarningAction.snooze);
            case _actionStart:
              _actions.add(WarningAction.startNow);
            case _actionSkip:
              _actions.add(WarningAction.skip);
          }
        }, onError: (Object _) {});

    // The daemon tells us when a notification dies — user dismissal, timeout,
    // or shell restart. Forgetting the id here is what keeps us from ever
    // reusing a dead one as `replaces_id`.
    _closedSub =
        DBusSignalStream(
          _bus,
          sender: _dest,
          interface: _iface,
          name: 'NotificationClosed',
          signature: DBusSignature('uu'),
        ).listen((signal) {
          if (signal.values[0].asUint32() == _activeId) _activeId = 0;
        }, onError: (Object _) {});
  }

  static const _dest = 'org.freedesktop.Notifications';
  static const _path = '/org/freedesktop/Notifications';
  static const _iface = 'org.freedesktop.Notifications';
  static const _actionSnooze = 'snooze';
  static const _actionStart = 'start';
  static const _actionSkip = 'skip';

  final DBusClient _bus;

  final _actions = StreamController<WarningAction>.broadcast();
  late final StreamSubscription<DBusSignal> _actionSub;
  late final StreamSubscription<DBusSignal> _closedSub;

  /// The id of the notification currently on screen, or 0 when none is.
  int _activeId = 0;

  /// Serializes Notify/CloseNotification so a dismiss can never overtake the
  /// show whose reply carries the id it needs to dismiss.
  Future<void> _queue = Future.value();

  @override
  Stream<WarningAction> get actions => _actions.stream;

  DBusRemoteObject get _object =>
      DBusRemoteObject(_bus, name: _dest, path: DBusObjectPath(_path));

  Future<void> _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) => op()).catchError((Object _) {});
    return _queue;
  }

  @override
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
    required bool canSkip,
  }) => _enqueue(() async {
    final title = kind == BreakKind.micro
        ? 'Eye break in ${startsIn.inSeconds}s'
        : 'Long break in ${startsIn.inSeconds}s';
    final body = kind == BreakKind.micro
        ? 'Time to rest your eyes for a moment.'
        : 'Time to stand up and move.';
    try {
      final reply = await _object.callMethod(_iface, 'Notify', [
        const DBusString(Brand.appName),
        // Only ever a live id: 0 starts a fresh banner, a live id replaces the
        // current one in place (the re-warn case) without stacking.
        DBusUint32(_activeId),
        const DBusString(Brand.appId),
        DBusString(title),
        DBusString(body),
        DBusArray.string([
          _actionStart,
          'Start now',
          if (canSnooze) ...[_actionSnooze, 'Snooze'],
          if (canSkip) ...[_actionSkip, 'Skip'],
        ]),
        DBusDict.stringVariant(const {
          'urgency': DBusVariant(DBusByte(1)), // normal: a heads-up, not alarm
          // Lets the desktop attach our icon and app name to the notification.
          'desktop-entry': DBusVariant(DBusString(Brand.appId)),
          // Sound is played by SoundPlayer, not hinted here: one mechanism and
          // one Settings toggle beats two that can drift apart.
        }),
        DBusInt32(startsIn.inMilliseconds),
      ], replySignature: DBusSignature('u'));
      _activeId = reply.returnValues[0].asUint32();
    } on DBusMethodResponseException {
      // No notification daemon — the overlay still enforces the break.
    }
  });

  @override
  Future<void> showInfo({required String title, required String body}) =>
      _enqueue(() async {
        try {
          await _object.callMethod(_iface, 'Notify', [
            const DBusString(Brand.appName),
            const DBusUint32(0), // never replaces the break warning
            const DBusString(Brand.appId),
            DBusString(title),
            DBusString(body),
            DBusArray.string(const []),
            DBusDict.stringVariant({
              'desktop-entry': const DBusVariant(DBusString(Brand.appId)),
            }),
            const DBusInt32(10000),
          ], replySignature: DBusSignature('u'));
        } on DBusMethodResponseException {
          // No notification daemon.
        }
      });

  @override
  Future<void> dismissWarning() => _enqueue(() async {
    if (_activeId == 0) return;
    final id = _activeId;
    _activeId = 0; // forget it first: a failed close must not resurrect the id
    try {
      await _object.callMethod(_iface, 'CloseNotification', [
        DBusUint32(id),
      ], replySignature: DBusSignature(''));
    } on DBusMethodResponseException {
      // Already gone.
    }
  });

  @override
  Future<void> dispose() async {
    await _actionSub.cancel();
    await _closedSub.cancel();
    await _actions.close();
  }
}
