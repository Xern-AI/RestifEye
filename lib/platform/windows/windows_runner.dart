// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';

/// The method channel to the C++ runner (`windows/runner/desktop_bridge.cpp`).
///
/// Everything that needs a window procedure lives natively: the tray icon and
/// its menu, session lock and power broadcasts, the second-launch message, and
/// taking the foreground. A Dart callback used as a window procedure would run
/// on whatever thread Windows chooses, which is not a thread Dart may run on.
class WindowsRunner {
  WindowsRunner({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handle);
  }

  static const channelName = 'com.xernai.restifeye/windows';

  final MethodChannel _channel;
  final _session = StreamController<String>.broadcast();
  final _tray = StreamController<String>.broadcast();
  final _relaunches = StreamController<void>.broadcast();

  /// `lock`, `unlock`, `suspend` or `resume`.
  Stream<String> get sessionEvents => _session.stream;

  /// `open`, `togglePause` or `quit`.
  Stream<String> get trayEvents => _tray.stream;

  /// RestifEye was launched again while already running.
  Stream<void> get relaunches => _relaunches.stream;

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'session':
        _session.add(call.arguments as String);
      case 'tray':
        _tray.add(call.arguments as String);
      case 'relaunch':
        _relaunches.add(null);
    }
    return null;
  }

  /// Proves the native half exists; throws when the runner lacks the channel.
  Future<void> ping() async {
    final reply = await _channel.invokeMethod<String>('ping');
    if (reply != 'pong') throw StateError('runner answered $reply');
  }

  /// Registers for lock/unlock notifications. False when Windows refused.
  Future<bool> startSessionEvents() async =>
      await _channel.invokeMethod<bool>('startSessionEvents') ?? false;

  /// The tray icon edge in pixels at the window's current DPI.
  Future<int> trayIconSize() async =>
      await _channel.invokeMethod<int>('trayIconSize') ?? 16;

  /// Adds the tray icon, or replaces its image and tooltip when present.
  Future<bool> traySetIcon({
    required int size,
    required Uint8List bgra,
    required String tooltip,
  }) async =>
      await _channel.invokeMethod<bool>('traySetIcon', {
        'size': size,
        'bgra': bgra,
        'tooltip': tooltip,
      }) ??
      false;

  Future<void> traySetMenu({
    required String open,
    required String pause,
    required String quit,
  }) => _channel.invokeMethod<void>('traySetMenu', {
    'open': open,
    'pause': pause,
    'quit': quit,
  });

  Future<void> trayRemove() => _channel.invokeMethod<void>('trayRemove');

  /// Brings the window to the front even when another app owns the
  /// foreground, which a plain `SetForegroundWindow` is not allowed to do.
  Future<bool> forceForeground() async =>
      await _channel.invokeMethod<bool>('forceForeground') ?? false;

  /// Shows the window and returns only once Windows has shown it.
  Future<bool> showWindow() async =>
      await _channel.invokeMethod<bool>('showWindow') ?? false;

  /// Borderless over the whole monitor, or back to the previous frame.
  Future<bool> setFullScreen(bool on) async =>
      await _channel.invokeMethod<bool>('setFullScreen', {'on': on}) ?? false;

  /// Whether the full-screen break window is what fills the screen right now.
  Future<bool> coversScreen() async =>
      await _channel.invokeMethod<bool>('coversScreen') ?? false;
}
