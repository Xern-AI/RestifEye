// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../desktop/window_ops.dart';
import 'windows_runner.dart';

/// `window_manager` on Windows, with one difference: taking focus.
///
/// Windows only lets the app that owns the foreground hand it over, so a
/// break starting from the background with a plain `SetForegroundWindow`
/// just flashes the taskbar button. The keyboard then stays in the other app
/// and the break clock — which only runs while the break holds focus — would
/// stand still. The runner joins the foreground thread's input queue for the
/// hand-over, which Windows does allow.
class WindowsWindowOps extends WindowManagerOps {
  const WindowsWindowOps(this.runner);

  final WindowsRunner runner;

  @override
  Future<void> focus() async {
    try {
      if (await runner.forceForeground()) return;
    } on Object {
      // Fall through to the ordinary request.
    }
    await super.focus();
  }
}
