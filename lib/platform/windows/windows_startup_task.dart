// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../interfaces/autostart.dart';
import 'windows_runner.dart';

/// Start with Windows for the Store build, through the package's own
/// `StartupTask` (a packaged app has no business in the Run key, and Windows
/// would ignore it there).
///
/// Turning it off in Task Manager or Settings → Apps → Startup is final for
/// the app: Windows will not let an app re-enable a task the user disabled,
/// so the switch then reads off and stays off until the user turns it back
/// on in Windows.
class WindowsStartupTask implements Autostart {
  const WindowsStartupTask(this.runner);

  final WindowsRunner runner;

  @override
  Future<bool> isEnabled() async =>
      startupTaskOn(await runner.startupTask('startupState'));

  @override
  Future<void> setEnabled(bool enabled) async {
    final state = await runner.startupTask(
      enabled ? 'startupEnable' : 'startupDisable',
    );
    if (state == 'error') throw Exception('startup task unavailable');
  }
}

bool startupTaskOn(String state) =>
    state == 'enabled' || state == 'enabledByPolicy';
