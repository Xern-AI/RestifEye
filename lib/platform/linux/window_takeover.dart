// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:window_manager/window_manager.dart';

import '../../app/brand.dart';
import '../interfaces/overlay_controller.dart';
import 'window_ops.dart';

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
  WindowTakeover({this.onHiddenToBackground, WindowOps? ops})
    : _ops = ops ?? const WindowManagerOps();

  /// Invoked when the user closes the window and it hides to the
  /// background (used for the one-time "still running" notice).
  final void Function()? onHiddenToBackground;

  final WindowOps _ops;

  /// One frame at 60 Hz — the gap between quiescence samples below.
  static const _framePeriod = Duration(milliseconds: 16);

  /// Two consecutive idle observations, not one: a single sample can land in
  /// the gap between an animation's frames and read as quiet when it is not.
  static const _idleSamplesRequired = 2;

  /// How long to wait for the renderer to go quiet before giving up and
  /// leaving the window on screen for the next tick to retry. Deliberately
  /// under a second, so a retry costs one reconciliation tick.
  static const _quiesceBudget = Duration(milliseconds: 600);

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

  /// A hide that has been decided but not yet performed.
  ///
  /// Unmapping a window on Wayland destroys its EGL surface immediately, but
  /// the toolkit will still draw the Flutter texture into it if a frame is
  /// already in flight: `gdk_cairo_draw_from_gl` then dereferences a freed
  /// `wl_surface` and the process dies with SIGSEGV. Two coredumps, both
  /// stamped the exact second a break ended.
  ///
  /// Break end is the one place this reliably bit. The exercise illustration
  /// animates continuously, so a frame is always in the air, and dropping
  /// fullscreen one step earlier adds a resize burst on top; closing an idle
  /// window to the tray — the path that had existed for months — never had a
  /// frame to collide with. So the hide is a *desire*, held until the
  /// renderer is quiet and retried on the next tick if it is not.
  bool _pendingHide = false;

  @override
  Future<void> init() => _ops.prepare(title: Brand.appName, on: this);

  @override
  Future<void> apply(BreakWindowState desired) => _enqueue(() async {
    if (desired != _current) await _transition(desired);
    // Serviced on every tick, not only on transitions: a hide that could not
    // be performed safely a second ago has to get another chance without
    // waiting for the next phase change.
    await _servicePendingHide();
  });

  @override
  Future<void> forceRestore() => _enqueue(() async {
    // Bypasses the idempotence check on purpose: this exists for the case
    // where our idea of the window's state is wrong. It restores
    // presentation only, never visibility — the user reaching for the escape
    // hatch is looking at the window they want to keep.
    await _transition(BreakWindowState.normal, restoreVisibility: false);
  });

  @override
  Future<void> presentWindow() => _enqueue(() async {
    _pendingHide = false; // asked for explicitly; do not yank it away again
    await _ops.show();
    await _ops.focus();
  });

  @override
  Future<void> destroyWindow() => _ops.destroy();

  Future<void> _enqueue(Future<void> Function() op) {
    _queue = _queue.then((_) => op()).catchError((Object _) {});
    return _queue;
  }

  Future<void> _transition(
    BreakWindowState desired, {
    bool restoreVisibility = true,
  }) async {
    final entering = desired.inBreak && !_current.inBreak;
    final leaving = !desired.inBreak && _current.inBreak;

    if (desired.inBreak) {
      // Sampled before `show()`, and only on the way in, so a mid-break
      // re-assertion (windowed → fullscreen) cannot overwrite it with `true`.
      if (entering) _wasVisibleBeforeBreak = await _isVisible();
      _pendingHide = false; // a break supersedes an unfinished hide
      await _ops.show();
      // Set these unconditionally in both directions — a previous break may
      // have left them on, and a windowed break must clear them.
      await _ops.setFullScreen(desired.fullscreen);
      await _ops.setAlwaysOnTop(desired.fullscreen);
      await _ops.focus();
    } else {
      await _ops.setAlwaysOnTop(false);
      await _ops.setFullScreen(false);
      // Put the window back the way we found it.
      if (leaving && restoreVisibility && !_wasVisibleBeforeBreak) {
        _pendingHide = true;
      }
    }
    _current = desired;
  }

  /// Performs a decided hide, once it is safe to unmap the window.
  ///
  /// Leaves the flag set when the renderer is still busy: the reconciler
  /// re-applies the phase every second, so the window hides a tick late
  /// instead of taking the process with it.
  Future<void> _servicePendingHide() async {
    if (!_pendingHide) return;
    if (!await _rendererQuiesced()) return;
    await _ops.hide();
    _pendingHide = false; // only once the window agrees, as everywhere else
  }

  /// Waits for the renderer to stop scheduling frames, up to
  /// [_quiesceBudget]. False if it never settles.
  Future<bool> _rendererQuiesced() async {
    final samples =
        _quiesceBudget.inMilliseconds ~/ _framePeriod.inMilliseconds;
    var idle = 0;
    for (var i = 0; i < samples; i++) {
      idle = _ops.isRendering ? 0 : idle + 1;
      if (idle >= _idleSamplesRequired) return true;
      await Future<void>.delayed(_framePeriod);
    }
    return false;
  }

  /// Treats an unreadable visibility as "was on screen": the failure mode of
  /// guessing wrong is a window left open, which the user can close. Guessing
  /// the other way would hide a window they were using.
  Future<bool> _isVisible() async {
    try {
      return await _ops.isVisible();
    } on Object {
      return true;
    }
  }

  /// Closing the window hides it — the engine keeps running. Quitting is
  /// explicit (tray menu, or Ctrl+Q).
  @override
  void onWindowClose() async {
    if (_current.inBreak) return; // no closing your way out of a break
    _pendingHide = true;
    unawaited(_enqueue(_servicePendingHide));
    // Announced on the decision rather than on the unmap: "still running in
    // the background" is true the moment the close is accepted.
    onHiddenToBackground?.call();
  }

  @override
  void onWindowBlur() async {
    if (_current.inBreak && _current.strict) {
      await _ops.focus(); // best-effort re-assert during strict
    }
  }
}
