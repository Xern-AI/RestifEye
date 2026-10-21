// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:dbus/dbus.dart';

import '../../app/platform_adapters.dart';
import '../desktop/window_ops.dart';
import 'github_update_checker.dart';
import 'gnome_tray_support.dart';
import 'linux_break_notifier.dart';
import 'linux_context_signals.dart';
import 'linux_idle_monitor.dart';
import 'linux_presentation_signals.dart';
import 'linux_session_signals.dart';
import 'linux_sound_player.dart';
import 'sni_tray.dart';
import 'xdg_autostart.dart';

/// The D-Bus/XDG adapters, sharing one session and one system bus.
PlatformAdapters linuxAdapters({required bool soundsEnabled}) {
  final sessionBus = DBusClient.session();
  final systemBus = DBusClient.system();
  return (
    notifier: LinuxBreakNotifier(sessionBus),
    sounds: LinuxSoundPlayer(enabled: soundsEnabled),
    traySupport: GnomeTraySupport(sessionBus),
    windowOps: const WindowManagerOps(),
    autostart: XdgAutostart(),
    updateChecker: GithubUpdateChecker(),
    idle: LinuxIdleMonitor(sessionBus),
    session: LinuxSessionSignals(session: sessionBus, system: systemBus),
    context: LinuxContextSignals(),
    presentation: LinuxPresentationSignals(
      session: sessionBus,
      system: systemBus,
    ),
    tray: SniTrayIndicator(sessionBus),
    traySizes: null,
    relaunches: const Stream<void>.empty(),
  );
}
