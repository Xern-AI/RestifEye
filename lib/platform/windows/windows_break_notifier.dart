// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';
import 'package:path/path.dart' as p;

import '../../app/brand.dart';
import '../../core/models/break_kind.dart';
import '../interfaces/app_log.dart';
import '../interfaces/break_notifier.dart';

/// What one toast says and offers, independent of the plugin that shows it.
class ToastSpec {
  const ToastSpec({
    required this.title,
    required this.body,
    this.actions = const [],
    this.stayOnScreen = false,
  });

  final String title;
  final String body;

  /// Button argument and label, in order.
  final List<(String, String)> actions;

  /// Kept on screen until acted on (Windows' "reminder" scenario), for the
  /// notice the user must not miss. Otherwise the long banner (~25 s), which
  /// covers the 30-second warning lead.
  final bool stayOnScreen;
}

/// Shows and clears toasts; the seam between the notifier's rules and the
/// Windows notification plugin.
abstract interface class ToastBackend {
  /// False when Windows refused to register the app for notifications.
  Future<bool> initialize(void Function(String argument) onActivated);

  /// Shows [spec], replacing any toast already shown with the same [id].
  Future<void> show(int id, ToastSpec spec);

  /// Removes every toast this app has shown, from screen and Action Center.
  Future<void> clearAll();
}

/// Break warnings as Windows toasts with Start now / Snooze / Skip buttons.
///
/// Removal keeps the rule the Linux notifier earned in QA round 8: the
/// warning is on screen exactly while the engine is in its warning phase, and
/// the coordinator takes it down from the phase. An unpackaged app can only
/// clear *all* of its toasts, not one, so dismissing a warning also clears an
/// older informational toast. The warning and the on-hold notice never
/// coexist (one belongs to the warning phase, the other to a break), so that
/// is the only side effect. The packaged Store build can remove a single one.
class WindowsBreakNotifier implements BreakNotifier {
  WindowsBreakNotifier({required this.backend, required this.log});

  static const _warningId = 1;
  static const _heldId = 2;
  static const _infoId = 3;

  final ToastBackend backend;
  final AppLog log;

  final _actions = StreamController<WarningAction>.broadcast();
  bool _warningLive = false;
  bool _heldLive = false;
  bool _ready = false;

  /// Serialized like the Linux notifier: a dismiss must never overtake the
  /// show it is meant to take down.
  Future<void> _queue = Future.value();

  /// Registers with Windows. Throws on refusal, so startup can log it.
  Future<void> start() async {
    _ready = await backend.initialize(_onActivated);
    if (!_ready) throw StateError('Windows refused notification registration');
  }

  void _onActivated(String argument) {
    final action = warningActionFor(argument);
    if (action != null && !_actions.isClosed) _actions.add(action);
  }

  Future<void> _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) async {
      if (!_ready) return;
      try {
        await op();
      } on Object catch (e) {
        log.failure('notifications', e);
      }
    });
    return _queue;
  }

  @override
  Stream<WarningAction> get actions => _actions.stream;

  @override
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
    required bool canSkip,
  }) => _enqueue(() async {
    await backend.show(
      _warningId,
      warningToast(
        kind: kind,
        startsIn: startsIn,
        canSnooze: canSnooze,
        canSkip: canSkip,
      ),
    );
    _warningLive = true;
  });

  @override
  Future<void> dismissWarning() => _enqueue(() async {
    if (!_warningLive) return;
    _warningLive = false;
    await backend.clearAll();
  });

  @override
  Future<void> showBreakHeld({required BreakKind kind}) => _enqueue(() async {
    await backend.show(_heldId, heldToast(kind));
    _heldLive = true;
  });

  @override
  Future<void> dismissBreakHeld() => _enqueue(() async {
    if (!_heldLive) return;
    _heldLive = false;
    await backend.clearAll();
  });

  @override
  Future<void> showInfo({required String title, required String body}) =>
      _enqueue(
        () => backend.show(_infoId, ToastSpec(title: title, body: body)),
      );

  @override
  Future<void> dispose() => _actions.close();
}

const _start = 'start';
const _snooze = 'snooze';
const _skip = 'skip';
const _return = 'return';

/// Button arguments back to engine actions. A click on the toast body (an
/// empty argument) does nothing, as on Linux.
WarningAction? warningActionFor(String argument) => switch (argument) {
  _start => WarningAction.startNow,
  _snooze => WarningAction.snooze,
  _skip => WarningAction.skip,
  _return => WarningAction.returnToBreak,
  _ => null,
};

/// Same words as the Linux banner, so both platforms read alike.
ToastSpec warningToast({
  required BreakKind kind,
  required Duration startsIn,
  required bool canSnooze,
  required bool canSkip,
}) => ToastSpec(
  title: kind == BreakKind.micro
      ? 'Eye break in ${startsIn.inSeconds}s'
      : 'Long break in ${startsIn.inSeconds}s',
  body: kind == BreakKind.micro
      ? 'Time to rest your eyes for a moment.'
      : 'Time to stand up and move.',
  actions: [
    (_start, 'Start now'),
    if (canSnooze) (_snooze, 'Snooze'),
    if (canSkip) (_skip, 'Skip'),
  ],
);

ToastSpec heldToast(BreakKind kind) => ToastSpec(
  title: 'Break paused',
  body:
      'Come back to ${Brand.appName} to finish your '
      '${kind == BreakKind.micro ? 'eye break' : 'movement break'}.',
  actions: const [(_return, 'Return to break')],
  stayOnScreen: true,
);

/// The real toasts, through `flutter_local_notifications_windows`.
///
/// Every toast is silent: sounds come from `SoundPlayer`, one mechanism with
/// one Settings switch, exactly as on Linux.
class PluginToastBackend implements ToastBackend {
  PluginToastBackend();

  /// Identifies the app to Windows' notification settings. Fixed forever:
  /// changing it would orphan the user's notification preferences.
  static const appUserModelId = 'Xernai.RestifEye';

  /// The COM class Windows calls when a toast button is pressed.
  static const activatorGuid = 'bc303b9f-40e0-4d6d-9a9c-d7f1bd3af46f';

  final _plugin = FlutterLocalNotificationsWindows();

  @override
  Future<bool> initialize(void Function(String argument) onActivated) =>
      _plugin.initialize(
        settings: WindowsInitializationSettings(
          appName: Brand.appName,
          appUserModelId: appUserModelId,
          guid: activatorGuid,
          iconPath: p.join(
            p.dirname(Platform.resolvedExecutable),
            'data',
            'restifeye.png',
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onActivated(response.actionId ?? ''),
      );

  @override
  Future<void> show(int id, ToastSpec spec) => _plugin.show(
    id: id,
    title: spec.title,
    body: spec.body,
    notificationDetails: WindowsNotificationDetails(
      actions: [
        for (final (argument, label) in spec.actions)
          WindowsAction(content: label, arguments: argument),
      ],
      audio: WindowsNotificationAudio.silent(),
      duration: spec.stayOnScreen ? null : WindowsNotificationDuration.long,
      scenario: spec.stayOnScreen ? WindowsNotificationScenario.reminder : null,
    ),
  );

  @override
  Future<void> clearAll() => _plugin.cancelAll();
}
