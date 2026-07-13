import 'dart:async';

import 'package:dbus/dbus.dart';

import '../../core/models/break_kind.dart';
import '../interfaces/break_notifier.dart';

/// Warning notifications via org.freedesktop.Notifications — no plugin
/// needed, works on every major desktop.
class LinuxBreakNotifier implements BreakNotifier {
  LinuxBreakNotifier(this._bus) {
    final signals = DBusSignalStream(
      _bus,
      sender: _dest,
      interface: _iface,
      name: 'ActionInvoked',
      signature: DBusSignature('us'),
    );
    _signalSub = signals.listen((signal) {
      if (signal.values[0].asUint32() != _activeId) return;
      switch (signal.values[1].asString()) {
        case _actionSnooze:
          _actions.add(WarningAction.snooze);
        case _actionStart:
          _actions.add(WarningAction.startNow);
      }
    }, onError: (Object _) {});
  }

  static const _dest = 'org.freedesktop.Notifications';
  static const _path = '/org/freedesktop/Notifications';
  static const _iface = 'org.freedesktop.Notifications';
  static const _actionSnooze = 'snooze';
  static const _actionStart = 'start';

  final DBusClient _bus;
  final _actions = StreamController<WarningAction>.broadcast();
  late final StreamSubscription<DBusSignal> _signalSub;
  int _activeId = 0;

  @override
  Stream<WarningAction> get actions => _actions.stream;

  @override
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
  }) async {
    final title = kind == BreakKind.micro
        ? 'Eye break in ${startsIn.inSeconds}s'
        : 'Long break in ${startsIn.inSeconds}s';
    final body = kind == BreakKind.micro
        ? 'Time to rest your eyes for a moment.'
        : 'Time to stand up and move.';
    try {
      final object = DBusRemoteObject(
        _bus,
        name: _dest,
        path: DBusObjectPath(_path),
      );
      final reply = await object.callMethod(_iface, 'Notify', [
        const DBusString('BreakTime'),
        DBusUint32(_activeId), // replaces the previous warning if visible
        const DBusString('com.xernai.breaktime'),
        DBusString(title),
        DBusString(body),
        DBusArray.string([
          _actionStart,
          'Start now',
          if (canSnooze) ...[_actionSnooze, 'Snooze'],
        ]),
        DBusDict.stringVariant({'urgency': const DBusVariant(DBusByte(1))}),
        DBusInt32(startsIn.inMilliseconds),
      ], replySignature: DBusSignature('u'));
      _activeId = reply.returnValues[0].asUint32();
    } on DBusMethodResponseException {
      // No notification daemon — the overlay still enforces the break.
    }
  }

  @override
  Future<void> showInfo({required String title, required String body}) async {
    try {
      final object = DBusRemoteObject(
        _bus,
        name: _dest,
        path: DBusObjectPath(_path),
      );
      await object.callMethod(_iface, 'Notify', [
        const DBusString('BreakTime'),
        const DBusUint32(0),
        const DBusString('com.xernai.breaktime'),
        DBusString(title),
        DBusString(body),
        DBusArray.string(const []),
        DBusDict.stringVariant(const {}),
        const DBusInt32(10000),
      ], replySignature: DBusSignature('u'));
    } on DBusMethodResponseException {
      // No notification daemon.
    }
  }

  @override
  Future<void> dismissWarning() async {
    if (_activeId == 0) return;
    try {
      final object = DBusRemoteObject(
        _bus,
        name: _dest,
        path: DBusObjectPath(_path),
      );
      await object.callMethod(_iface, 'CloseNotification', [
        DBusUint32(_activeId),
      ], replySignature: DBusSignature(''));
    } on DBusMethodResponseException {
      // Already gone.
    }
    _activeId = 0;
  }

  @override
  Future<void> dispose() async {
    await _signalSub.cancel();
    await _actions.close();
  }
}
