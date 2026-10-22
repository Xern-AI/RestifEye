// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../desktop/window_ops.dart';
import '../interfaces/app_log.dart';
import 'windows_runner.dart';

/// `window_manager` on Windows, with the parts that misbehaved there done by
/// the runner instead. Every step is logged, because a window that ends up
/// in the wrong state is otherwise invisible in a bug report.
///
/// * **Show** is synchronous. `window_manager` uses `ShowWindowAsync`, so the
///   full-screen and focus calls that follow ran against a still-hidden
///   window: the first Windows test got a frameless window at its old size,
///   without focus, its break clock on hold.
/// * **Full screen** is a borderless window sized to the monitor, made by the
///   runner on the now-visible window.
/// * **Focus** joins the foreground thread's input queue, since Windows
///   refuses the foreground to background apps.
/// * **Attending** also counts a full-screen break that still covers the
///   screen. A topmost break stays in front through Alt+Tab, so the user is
///   still looking at it even though another app holds the keyboard;
///   Win+D or minimising uncovers the screen and does hold the clock.
/// * **Rendering** never delays a hide. That gate exists for a GTK crash
///   (painting into an unmapped Wayland surface) that Windows does not have,
///   and on Windows a frame can stay scheduled while nothing is drawn, which
///   kept the window on screen forever after a break.
class WindowsWindowOps extends WindowManagerOps {
  const WindowsWindowOps(this.runner, this.log);

  final WindowsRunner runner;
  final AppLog log;

  @override
  Future<void> show() => _step('show', () async {
    if (!await runner.showWindow()) throw StateError('still hidden');
  });

  @override
  Future<void> hide() => _step('hide', super.hide);

  @override
  Future<void> setFullScreen(bool value) =>
      _step('full screen ${value ? 'on' : 'off'}', () async {
        if (!await runner.setFullScreen(value)) {
          throw StateError('runner refused');
        }
      });

  @override
  Future<void> setAlwaysOnTop(bool value) => _step(
    'on top ${value ? 'on' : 'off'}',
    () => super.setAlwaysOnTop(value),
  );

  @override
  Future<void> focus() async {
    var taken = false;
    try {
      taken = await runner.forceForeground();
    } on Object {
      // Fall through to the ordinary request.
    }
    if (!taken) await super.focus();
    log.info(taken ? 'window focus taken' : 'window focus refused by Windows');
  }

  @override
  Future<bool> isFocused() async =>
      await super.isFocused() || await runner.coversScreen();

  @override
  bool get isRendering => false;

  Future<void> _step(String name, Future<void> Function() op) async {
    try {
      await op();
      log.info('window $name');
    } on Object catch (e) {
      log.failure('window', '$name: $e');
      rethrow;
    }
  }
}
