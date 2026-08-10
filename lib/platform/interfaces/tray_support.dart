// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Why the tray icon is (or is not) visible, and what the user can do.
enum TrayState {
  /// A status-area host is running; the icon is showing.
  working,

  /// The required shell extension is installed but switched off — we can
  /// turn it on for the user with one click.
  extensionDisabled,

  /// The extension is not installed; offer to install it.
  extensionMissing,

  /// No status area and no way to add one (not GNOME, or no session bus).
  unavailable,
}

/// The tray's health, plus the human name of whatever the user must enable.
///
/// GNOME has shipped no status area since 3.26: the top-right corner next to
/// battery and wi-fi is only reachable through a shell extension acting as a
/// StatusNotifierItem host. Rather than document that and hope, the app
/// detects it and offers to fix it.
class TraySupport {
  const TraySupport(this.state, {this.extensionName});

  final TrayState state;

  /// e.g. "AppIndicator and KStatusNotifierItem Support" — named verbatim so
  /// the user can tell which of their extensions is the one that matters.
  final String? extensionName;
}

abstract interface class TrayHostSupport {
  Future<TraySupport> check();

  /// Turns the extension on (installing it first if needed). Returns the
  /// state afterwards, so the UI can report success or failure honestly.
  Future<TraySupport> enable();
}
