import 'package:window_manager/window_manager.dart';

import '../interfaces/overlay_controller.dart';

/// Break-time window takeover via window_manager.
///
/// Honest Wayland note: compositors do not let a normal app grab input, so
/// strict mode is best-effort — fullscreen + always-on-top + refocus on
/// blur. The compliance log, not window tricks, is the real enforcement.
class WindowTakeover with WindowListener implements OverlayController {
  bool _strict = false;
  bool _inBreak = false;

  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setTitle('BreakTime');
  }

  @override
  Future<void> enterBreak({required bool strict}) async {
    _strict = strict;
    _inBreak = true;
    await windowManager.show();
    await windowManager.setFullScreen(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
  }

  @override
  Future<void> exitBreak() async {
    _inBreak = false;
    _strict = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setFullScreen(false);
  }

  /// Closing the window hides it — the engine keeps running. Quitting is
  /// explicit via the app's menu.
  @override
  void onWindowClose() async {
    if (_inBreak) return; // no closing your way out of a break
    await windowManager.hide();
  }

  @override
  void onWindowBlur() async {
    if (_inBreak && _strict) {
      await windowManager.focus(); // best-effort re-assert during strict
    }
  }
}
