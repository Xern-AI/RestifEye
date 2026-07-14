import '../interfaces/overlay_controller.dart';

/// No-op overlay for tests and headless runs; records calls for assertions.
class FakeOverlayController implements OverlayController {
  final List<String> calls = [];

  /// The window state as this fake believes it to be — what a test asserts
  /// against to prove the user is not stuck in a full-screen window.
  BreakWindowState state = BreakWindowState.normal;

  bool destroyed = false;

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> apply(BreakWindowState desired) async {
    if (desired == state) return; // mirror the real controller's idempotence
    state = desired;
    calls.add('apply($desired)');
  }

  @override
  Future<void> presentWindow() async => calls.add('present');

  @override
  Future<void> forceRestore() async {
    state = BreakWindowState.normal;
    calls.add('forceRestore');
  }

  @override
  Future<void> destroyWindow() async {
    destroyed = true;
    calls.add('destroy');
  }
}
