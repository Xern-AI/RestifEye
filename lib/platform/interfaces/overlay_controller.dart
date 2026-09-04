// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// The window presentation a given engine phase demands.
///
/// Deliberately a *state*, not a pair of enter/exit commands: the window is
/// derived from the engine phase and re-asserted every tick, so a dropped,
/// delayed or reordered signal cannot strand it.
class BreakWindowState {
  const BreakWindowState({
    required this.inBreak,
    required this.strict,
    required this.fullscreen,
  });

  /// The window as the user owns it: decorated, closable, not on top.
  static const normal = BreakWindowState(
    inBreak: false,
    strict: false,
    fullscreen: false,
  );

  final bool inBreak;

  /// Re-assert focus when the window loses it (best-effort on Wayland).
  final bool strict;

  /// Seize the whole screen and stay above other windows.
  final bool fullscreen;

  @override
  bool operator ==(Object other) =>
      other is BreakWindowState &&
      other.inBreak == inBreak &&
      other.strict == strict &&
      other.fullscreen == fullscreen;

  @override
  int get hashCode => Object.hash(inBreak, strict, fullscreen);

  @override
  String toString() => inBreak
      ? 'BreakWindowState(break, strict: $strict, fullscreen: $fullscreen)'
      : 'BreakWindowState(normal)';
}

/// Controls the app window. The macOS-port seam: everything platform-specific
/// about presenting a break lives behind this.
abstract interface class OverlayController {
  /// Called once at startup (prevent-close-to-background, title, listeners).
  Future<void> init();

  /// Declares the window state the engine's current phase requires.
  ///
  /// Idempotent and serialized: safe to call on every tick, and concurrent
  /// calls can never land out of order. Failures leave the last known-good
  /// state in place so the next tick retries.
  Future<void> apply(BreakWindowState desired);

  /// Whether the window currently has keyboard focus.
  ///
  /// Polled rather than latched from focus events, for the same reason the
  /// window state is: a missed event would leave the break clock stuck.
  /// Implementations answer `true` when they cannot tell, so an unreadable
  /// desktop can never freeze a break forever.
  Future<bool> hasFocus();

  /// Brings the (possibly hidden) window to the front — tray, or relaunch.
  Future<void> presentWindow();

  /// Unconditionally leaves break presentation, whatever we believe the
  /// current state to be. The user's escape hatch; must always work.
  Future<void> forceRestore();

  /// Tears the window down for a real quit.
  Future<void> destroyWindow();
}
