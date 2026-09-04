// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../interfaces/overlay_controller.dart';

/// No-op overlay for tests and headless runs; records calls for assertions.
class FakeOverlayController implements OverlayController {
  final List<String> calls = [];

  /// The window state as this fake believes it to be — what a test asserts
  /// against to prove the user is not stuck in a full-screen window.
  BreakWindowState state = BreakWindowState.normal;

  bool destroyed = false;

  /// What [hasFocus] reports; tests flip it to simulate an alt-tab.
  bool focused = true;

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> apply(BreakWindowState desired) async {
    if (desired == state) return; // mirror the real controller's idempotence
    state = desired;
    calls.add('apply($desired)');
  }

  @override
  Future<bool> hasFocus() async => focused;

  @override
  Future<void> presentWindow() async => calls.add('present');

  @override
  Future<void> forceRestore() async {
    state = BreakWindowState.normal;
    calls.add('forceRestore');
  }

  @override
  Future<void> destroyWindow() async {
    destroyed = true;
    calls.add('destroy');
  }
}
