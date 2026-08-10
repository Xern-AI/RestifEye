// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:io';

import '../platform/interfaces/overlay_controller.dart';
import '../platform/interfaces/tray_indicator.dart';
import 'mood_service.dart';
import 'engine_service.dart';

/// The single way out of the app, shared by the tray menu and Ctrl+Q.
///
/// There must always be exactly one of these and it must always work: a
/// break reminder that can seize the screen has an obligation to be
/// quittable from anywhere, at any time.
class AppLifecycle {
  AppLifecycle({
    required this.overlay,
    required this.service,
    required this.tray,
    this.mood,
    this.exitProcess = exit,
  });

  final OverlayController overlay;
  final EngineService service;
  final TrayIndicator tray;

  /// Null in tests and on the paths that never start it.
  final MoodService? mood;

  /// Injected so tests can quit without killing the test runner.
  final void Function(int code) exitProcess;

  bool _quitting = false;

  /// Flushes state to disk, then goes. Idempotent — a double-click on Quit
  /// must not race two disposals.
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    try {
      await tray.dispose();
      await mood?.dispose();
      await service.dispose();
      await overlay.destroyWindow();
    } finally {
      exitProcess(0);
    }
  }
}
