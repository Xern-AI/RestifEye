import 'dart:io';

import '../platform/interfaces/overlay_controller.dart';
import '../platform/interfaces/tray_indicator.dart';
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
    this.exitProcess = exit,
  });

  final OverlayController overlay;
  final EngineService service;
  final TrayIndicator tray;

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
      await service.dispose();
      await overlay.destroyWindow();
    } finally {
      exitProcess(0);
    }
  }
}
