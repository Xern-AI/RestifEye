import 'dart:async';

import '../interfaces/autostart.dart';
import '../interfaces/context_signals.dart';
import '../interfaces/idle_monitor.dart';
import '../interfaces/session_signals.dart';
import '../interfaces/tray_indicator.dart';

/// Deterministic platform fakes for tests and dev mode.
class FakeIdleMonitor implements IdleMonitor {
  Duration idle = Duration.zero;

  @override
  Future<Duration> currentIdle() async => idle;

  @override
  Future<void> dispose() async {}
}

class FakeSessionSignals implements SessionSignals {
  final _controller = StreamController<bool>.broadcast();

  void setAway(bool value) => _controller.add(value);

  @override
  Stream<bool> get away => _controller.stream;

  @override
  Future<void> dispose() => _controller.close();
}

class FakeContextSignals implements ContextSignals {
  bool busy = false;

  @override
  Future<bool> isBusy() async => busy;
}

class FakeAutostart implements Autostart {
  bool enabled = false;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
}

class FakeTrayIndicator implements TrayIndicator {
  final _controller = StreamController<TrayAction>.broadcast();
  bool paused = false;
  bool disposed = false;

  void select(TrayAction action) => _controller.add(action);

  @override
  Future<void> init({required List<TrayPixmap> icons}) async {}

  @override
  Future<void> setPaused(bool value) async => paused = value;

  @override
  Stream<TrayAction> get actions => _controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}
