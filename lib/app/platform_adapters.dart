// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../platform/desktop/window_ops.dart';
import '../platform/interfaces/autostart.dart';
import '../platform/interfaces/break_notifier.dart';
import '../platform/interfaces/context_signals.dart';
import '../platform/interfaces/idle_monitor.dart';
import '../platform/interfaces/presentation_signals.dart';
import '../platform/interfaces/session_signals.dart';
import '../platform/interfaces/sound_player.dart';
import '../platform/interfaces/tray_indicator.dart';
import '../platform/interfaces/tray_support.dart';
import '../platform/interfaces/update_checker.dart';

/// One operating system's implementations of every platform seam.
/// `bootstrap()` builds the rest of the app on top of whichever set it gets.
typedef PlatformAdapters = ({
  BreakNotifier notifier,
  SoundPlayer sounds,
  TrayHostSupport traySupport,
  WindowOps windowOps,
  Autostart autostart,

  /// Null where the app does not check for updates itself.
  UpdateChecker? updateChecker,
  IdleMonitor idle,
  SessionSignals session,
  ContextSignals context,
  PresentationSignals presentation,
  TrayIndicator tray,

  /// Tray face sizes to draw; null keeps the default set.
  List<int>? traySizes,

  /// The app was launched again while running and should show its window.
  /// Linux handles this in the GTK runner, so its stream is empty.
  Stream<void> relaunches,
});
