// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';

/// The window and renderer facts [WindowTakeover] acts on, behind an
/// interface.
///
/// This is *not* the portability seam — `OverlayController` is. It exists
/// because every bug this area has produced has been one of ordering, not of
/// any single call: a late fullscreen landing after a restore, and an unmap
/// landing while a frame was still in flight. Ordering is exactly what a
/// fake can prove and a real compositor cannot.
///
/// [isRendering] sits here rather than in a seam of its own because it
/// answers a question about the same object: whether the surface these calls
/// mutate is safe to pull out from under the toolkit right now.
abstract interface class WindowOps {
  /// One-time setup: binding, close interception, title, event listener.
  Future<void> prepare({required String title, required WindowListener on});

  Future<void> show();
  Future<void> hide();
  Future<void> focus();
  Future<void> setFullScreen(bool value);
  Future<void> setAlwaysOnTop(bool value);
  Future<bool> isVisible();
  Future<bool> isFocused();
  Future<void> destroy();

  /// Whether the renderer has a frame scheduled — i.e. whether the toolkit
  /// is about to draw into this window's surface.
  bool get isRendering;
}

/// The real window, driven by `window_manager`.
class WindowManagerOps implements WindowOps {
  const WindowManagerOps();

  @override
  Future<void> prepare({
    required String title,
    required WindowListener on,
  }) async {
    await windowManager.ensureInitialized();
    windowManager.addListener(on);
    await windowManager.setPreventClose(true);
    await windowManager.setTitle(title);
  }

  @override
  Future<void> show() => windowManager.show();

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> focus() => windowManager.focus();

  @override
  Future<void> setFullScreen(bool value) => windowManager.setFullScreen(value);

  @override
  Future<void> setAlwaysOnTop(bool value) =>
      windowManager.setAlwaysOnTop(value);

  @override
  Future<bool> isVisible() => windowManager.isVisible();

  @override
  Future<bool> isFocused() => windowManager.isFocused();

  @override
  Future<void> destroy() => windowManager.destroy();

  /// The scheduler is the only thing that knows a frame is coming before the
  /// toolkit tries to draw it.
  @override
  bool get isRendering => SchedulerBinding.instance.hasScheduledFrame;
}
