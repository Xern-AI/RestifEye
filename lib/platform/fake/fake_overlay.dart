import '../interfaces/overlay_controller.dart';

/// No-op overlay for tests and headless runs; records calls for assertions.
class FakeOverlayController implements OverlayController {
  final List<String> calls = [];

  @override
  Future<void> init() async => calls.add('init');

  @override
  Future<void> enterBreak({
    required bool strict,
    required bool fullscreen,
  }) async => calls.add('enter(strict: $strict, fullscreen: $fullscreen)');

  @override
  Future<void> exitBreak() async => calls.add('exit');
}
