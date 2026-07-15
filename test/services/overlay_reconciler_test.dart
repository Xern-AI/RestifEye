import 'package:restifeye/core/engine/phase.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/platform/interfaces/overlay_controller.dart';
import 'package:restifeye/services/overlay_reconciler.dart';
// flutter_test also exports an unrelated EnginePhase (the Flutter engine's).
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;

void main() {
  const monitoring = Monitoring(
    nextBreakIn: Duration(minutes: 5),
    nextBreakKind: BreakKind.micro,
    microIn: Duration(minutes: 5),
    longIn: Duration(minutes: 30),
  );

  InBreak inBreak({required bool strict}) => InBreak(
    kind: BreakKind.micro,
    remaining: const Duration(seconds: 20),
    snoozesLeft: strict ? 0 : 3,
    strict: strict,
  );

  group('desiredWindowState', () {
    test('every non-break phase wants a normal window', () {
      const phases = <EnginePhase>[
        monitoring,
        Warning(kind: BreakKind.micro, startsIn: Duration(seconds: 30)),
        Deferred(kind: BreakKind.long, recheckIn: Duration(minutes: 5)),
        Paused(byUser: true),
        Paused(byUser: false),
      ];
      for (final phase in phases) {
        expect(
          desiredWindowState(phase, fullscreenPreferred: true),
          BreakWindowState.normal,
          reason: '$phase must never hold the window in break presentation',
        );
      }
    });

    test('a break honours the full-screen preference', () {
      expect(
        desiredWindowState(inBreak(strict: false), fullscreenPreferred: true),
        const BreakWindowState(inBreak: true, strict: false, fullscreen: true),
      );
      expect(
        desiredWindowState(inBreak(strict: false), fullscreenPreferred: false),
        const BreakWindowState(inBreak: true, strict: false, fullscreen: false),
      );
    });

    test('a strict break takes the screen even when the user opted out', () {
      expect(
        desiredWindowState(inBreak(strict: true), fullscreenPreferred: false),
        const BreakWindowState(inBreak: true, strict: true, fullscreen: true),
        reason: 'a strict break in a background window would be no break',
      );
    });
  });
}
