import 'dart:async';

import '../interfaces/context_signals.dart';
import '../interfaces/idle_monitor.dart';
import '../interfaces/session_signals.dart';

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
