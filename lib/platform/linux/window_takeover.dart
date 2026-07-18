import 'dart:async';

import 'package:window_manager/window_manager.dart';

import '../../app/brand.dart';
import '../interfaces/overlay_controller.dart';

/// Break-time window takeover via window_manager.
///
/// Honest Wayland note: compositors do not let a normal app grab input, so
/// strict mode is best-effort — fullscreen + always-on-top + refocus on
/// blur. The compliance log, not window tricks, is the real enforcement.
///
/// Every window mutation goes through one serialized queue. window_manager
/// calls are async, and two interleaved ones used to be able to land out of
/// order — a late `enterBreak` re-fullscreening *after* an `exitBreak` — which
/// left the window fullscreen, undecorated, always-on-top and refusing to
/// close, with no code path left that could undo it. State-based
/// reconciliation plus a queue makes that unrepresentable.
class WindowTakeover with WindowListener implements OverlayController {
  WindowTakeover({this.onHiddenToBackground});

  /// Invoked when the user closes the window and it hides to the
  /// background (used for the one-time "still running" notice).
  final void Function()? onHiddenToBackground;

  /// The last state we successfully pushed to the real window. Only ever
  /// advanced after the window agrees, so a failed transition is retried by
  /// the next tick rather than being silently assumed to have worked.
  BreakWindowState _current = BreakWindowState.normal;

  /// Serializes window mutations. Completed links are not retained, so
  /// chaining one closure per tick costs nothing over time.
  Future<void> _queue = Future.value();

  /// Whether the window was on screen before a break took it over.
  ///
  /// A break has to show the window; ending one used to just drop fullscreen
  /// and always-on-top, leaving the app sitting in the user's face until they
  /// dismissed it manually. Every break therefore ended with a chore. The
  /// window now goes back to whatever it was doing beforehand — which for the
  /// normal case (app closed to tray) means it disappears on its own.
  bool _wasVisibleBeforeBreak = true;

  @override
  Future<void> init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    await windowManager.setTitle(Brand.appName);
  }

  @override
  Future<void> apply(BreakWindowState desired) => _enqueue(() async {
    if (desired == _current) return; // 1 Hz re-assertion is free
    await _transition(desired);
  });

  @override
  Future<void> forceRestore() => _enqueue(() async {
    // Bypasses the idempotence check on purpose: this exists for the case
    // where our idea of the window's state is wrong.
    await _transition(BreakWindowState.normal);
  });

  @override
  Future<void> presentWindow() => _enqueue(() async {
    await windowManager.show();
    await windowManager.focus();
  });

  @override
  Future<void> destroyWindow() => windowManager.destroy();

  Future<void> _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) => op()).catchError((Object _) {});
    return _queue;
  }

  Future<void> _transition(BreakWindowState desired) async {
    final entering = desired.inBreak && !_current.inBreak;
    final leaving = !desired.inBreak && _current.inBreak;

    if (desired.inBreak) {
      // Sampled before `show()`, and only on the way in, so a mid-break
      // re-assertion (windowed → fullscreen) cannot overwrite it with `true`.
      if (entering) _wasVisibleBeforeBreak = await _isVisible();
      await windowManager.show();
      // Set these unconditionally in both directions — a previous break may
      // have left them on, and a windowed break must clear them.
      await windowManager.setFullScreen(desired.fullscreen);
      await windowManager.setAlwaysOnTop(desired.fullscreen);
      await windowManager.focus();
    } else {
      await windowManager.setAlwaysOnTop(false);
      await windowManager.setFullScreen(false);
      // Put the window back the way we found it. Guarded on `leaving` so
      // `forceRestore()` — which exists for when our idea of the state is
      // wrong — can never hide a window the user opened themselves.
      if (leaving && !_wasVisibleBeforeBreak) await windowManager.hide();
    }
    _current = desired;
  }

  /// Treats an unreadable visibility as "was on screen": the failure mode of
  /// guessing wrong is a window left open, which the user can close. Guessing
  /// the other way would hide a window they were using.
  Future<bool> _isVisible() async {
    try {
      return await windowManager.isVisible();
    } on Object {
      return true;
    }
  }

  /// Closing the window hides it — the engine keeps running. Quitting is
  /// explicit (tray menu, or Ctrl+Q).
  @override
  void onWindowClose() async {
    if (_current.inBreak) return; // no closing your way out of a break
    await windowManager.hide();
    onHiddenToBackground?.call();
  }

  @override
  void onWindowBlur() async {
    if (_current.inBreak && _current.strict) {
      await windowManager.focus(); // best-effort re-assert during strict
    }
  }
}
