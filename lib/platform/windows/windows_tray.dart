// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import '../../app/brand.dart';
import '../interfaces/app_log.dart';
import '../interfaces/tray_indicator.dart';
import 'windows_runner.dart';

/// The tray face in the Windows notification area, through the runner's
/// `Shell_NotifyIcon` code.
///
/// The faces are drawn at every size Windows uses from 100% to 300% display
/// scaling ([windowsTraySizes]); each update sends the one that matches the
/// window's current DPI exactly, so Windows never has to rescale the face.
class WindowsTrayIndicator implements TrayIndicator {
  WindowsTrayIndicator({required this.runner, required this.log}) {
    _sub = runner.trayEvents.listen((event) {
      final action = trayActionFor(event);
      if (action != null && !_actions.isClosed) _actions.add(action);
    });
  }

  final WindowsRunner runner;
  final AppLog log;

  final _actions = StreamController<TrayAction>.broadcast();
  late final StreamSubscription<String> _sub;
  String _tooltip = 'Running — breaks on schedule';
  bool _reported = false;

  @override
  Stream<TrayAction> get actions => _actions.stream;

  @override
  Future<void> init({required List<TrayPixmap> icons}) async {
    try {
      await _menu(paused: false);
      if (!await _show(icons)) throw StateError('Shell_NotifyIcon refused');
      log.info('adapter tray ok');
    } on Object catch (e) {
      log.failure('tray', e);
      rethrow;
    }
  }

  @override
  Future<void> setIcon(List<TrayPixmap> icons, {required String tooltip}) {
    _tooltip = tooltip;
    return _guard(() => _show(icons));
  }

  @override
  Future<void> setPaused(bool paused) => _guard(() => _menu(paused: paused));

  @override
  Future<void> dispose() async {
    await _sub.cancel();
    await _guard(runner.trayRemove);
    await _actions.close();
  }

  Future<bool> _show(List<TrayPixmap> icons) async {
    final icon = pickPixmap(icons, await runner.trayIconSize());
    return runner.traySetIcon(
      size: icon.width,
      bgra: argbToBgra(icon.argb32),
      tooltip: trayTooltip(_tooltip),
    );
  }

  Future<void> _menu({required bool paused}) => runner.traySetMenu(
    open: 'Open ${Brand.appName}',
    pause: paused ? 'Resume breaks' : 'Pause breaks',
    quit: 'Quit ${Brand.appName}',
  );

  Future<void> _guard(Future<Object?> Function() op) async {
    try {
      await op();
    } on Object catch (e) {
      if (!_reported) log.failure('tray', e);
      _reported = true;
    }
  }
}

/// Small-icon sizes at 100, 125, 150, 175, 200, 250 and 300% scaling.
const windowsTraySizes = [16, 20, 24, 28, 32, 40, 48];

TrayAction? trayActionFor(String event) => switch (event) {
  'open' => TrayAction.open,
  'togglePause' => TrayAction.togglePause,
  'quit' => TrayAction.quit,
  _ => null,
};

/// The exact size if offered, else the smallest larger one (shrinking blurs
/// less than enlarging), else the largest there is.
TrayPixmap pickPixmap(List<TrayPixmap> icons, int size) {
  final sorted = [...icons]..sort((a, b) => a.width.compareTo(b.width));
  return sorted.firstWhere((i) => i.width >= size, orElse: () => sorted.last);
}

/// SNI pixmaps are ARGB in network byte order; a Windows 32-bit DIB is BGRA
/// in memory. Alpha stays straight, which is what icons expect.
Uint8List argbToBgra(List<int> argb) {
  final out = Uint8List(argb.length);
  for (var i = 0; i + 3 < argb.length; i += 4) {
    out[i] = argb[i + 3];
    out[i + 1] = argb[i + 2];
    out[i + 2] = argb[i + 1];
    out[i + 3] = argb[i];
  }
  return out;
}

/// `NOTIFYICONDATAW.szTip` holds 127 UTF-16 units plus the terminator.
/// Clipped on a code-unit boundary that never splits a surrogate pair, since
/// half an emoji renders as a box.
String trayTooltip(String status, {int limit = 127}) {
  final text = '${Brand.appName}\n$status';
  if (text.length <= limit) return text;
  var end = limit - 1;
  final last = text.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end -= 1;
  return '${text.substring(0, end)}…';
}
