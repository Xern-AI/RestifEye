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

  /// Consecutive quiet reconciliation ticks a break-end hide must observe
  /// before the window is unmapped — roughly three seconds, since the hide is
  /// never serviced on the tick that decided it.
  static const _postBreakSettleTicks = 3;

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

  /// A hide that has been decided but not yet performed, and the number of
  /// consecutive quiet reconciliation ticks it must observe first. Null when
  /// no hide is pending.
  ///
  /// Unmapping a window on Wayland destroys its EGL surface immediately, but
  /// the toolkit will still draw the Flutter texture into it if a frame is
  /// already in flight: `gdk_cairo_draw_from_gl` then dereferences a freed
  /// `wl_surface` and the process dies with SIGSEGV. Four coredumps now, all
  /// stamped the exact second a break ended.
  ///
  /// [_rendererQuiesced] alone did not settle this, because it asks the wrong
  /// object. `hasScheduledFrame` is a *framework* fact — whether Dart intends
  /// to build another frame. The crash happens two stages downstream, in GDK's
  /// frame clock, drawing a frame the raster thread already handed to GTK. The
  /// flag goes false while that frame is still in the pipeline, so a hide one
  /// sample later still lands on a live paint.
  ///
  /// Nothing in Dart can observe GTK's paint queue, so the gate is time
  /// instead: [_postBreakSettleTicks] quiet ticks put seconds between the
  /// break and the unmap, where the pipeline drains in about two frames. The
  /// same wait clears the second hazard for free — `window_manager`'s `hide()`
  /// calls `gtk_window_resize()` *after* unmapping, which re-queues a paint
  /// whenever the size it reads is stale, and the compositor's unfullscreen
  /// configure has long since landed by then.
  ///
  /// Zero ticks for a user-initiated close: an idle window has nothing in the
  /// pipeline, that path has never crashed, and it has to feel instant.
  int? _hideAfterQuietTicks;

  /// Quiet ticks observed so far against [_hideAfterQuietTicks]. Consecutive,
  /// not cumulative — a busy sample resets it.
  int _quietTicks = 0;

  @override
  Future<void> init() => _ops.prepare(title: Brand.appName, on: this);

  @override
  Future<void> apply(BreakWindowState desired) => _enqueue(() async {
    if (desired != _current) {
      // A hide decided on this tick is never performed on it: the frame that
      // ended the break is still working its way through GTK.
      await _transition(desired);
      return;
    }
    // Serviced on every other tick, not only on transitions: a hide that could
    // not be performed safely a second ago has to get another chance without
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

  /// Read straight from the window on every ask. Treats an unreadable answer
  /// as focused: guessing wrong that way costs one second of break clock,
  /// while guessing the other way would hold a break open indefinitely.
  @override
  Future<bool> hasFocus() async {
    try {
      return await _ops.isFocused();
    } on Object {
      return true;
    }
  }

  @override
  Future<void> presentWindow() => _enqueue(() async {
    _cancelPendingHide(); // asked for explicitly; do not yank it away again
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
      _cancelPendingHide(); // a break supersedes an unfinished hide
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
        _scheduleHide(after: _postBreakSettleTicks);
      }
    }
    _current = desired;
  }

  void _scheduleHide({required int after}) {
    _hideAfterQuietTicks = after;
    _quietTicks = 0;
  }

  void _cancelPendingHide() {
    _hideAfterQuietTicks = null;
    _quietTicks = 0;
  }

  /// Performs a decided hide, once it is safe to unmap the window.
  ///
  /// Leaves the request standing when the renderer is still busy, or when it
  /// has not been quiet for long enough yet: the reconciler re-applies the
  /// phase every second, so the window hides a tick late instead of taking the
  /// process with it.
  Future<void> _servicePendingHide() async {
    final required = _hideAfterQuietTicks;
    if (required == null) return;
    if (!await _rendererQuiesced()) {
      _quietTicks = 0;
      return;
    }
    if (++_quietTicks < required) return;
    await _ops.hide();
    _cancelPendingHide(); // only once the window agrees, as everywhere else
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
    _scheduleHide(after: 0);
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
