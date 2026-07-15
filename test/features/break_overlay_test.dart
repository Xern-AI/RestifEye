import 'package:restifeye/app/app.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/features/breaks/break_overlay.dart';
import 'package:restifeye/features/breaks/hold_to_skip.dart';
import 'package:restifeye/platform/interfaces/overlay_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/overrides.dart';

void main() {
  Future<void> pumpToBreak(
    WidgetTester tester,
    TestHarness harness, {
    Duration lead = const Duration(minutes: 20, seconds: 5),
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness.wrap(const RestifEyeApp()));
    await tester.pump();
    harness.advance(lead);
    await tester.pump();
  }

  testWidgets('overlay appears when a break starts, without a snooze '
      'button (snoozing lives in the notification)', (tester) async {
    final harness = TestHarness();
    await pumpToBreak(tester, harness);

    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(find.text('Eye break'), findsOneWidget);
    expect(find.textContaining('Snooze'), findsNothing);
    expect(find.byType(HoldToSkip), findsOneWidget);
    expect(
      harness.overlay.state,
      const BreakWindowState(inBreak: true, strict: false, fullscreen: true),
    );

    await cleanupHarness(tester, harness);
  });

  testWidgets('strict break takes the screen and holding skip escapes it', (
    tester,
  ) async {
    final harness = TestHarness(config: const BreakConfig(snoozeBudget: 0));
    await pumpToBreak(tester, harness);

    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(
      harness.overlay.state,
      const BreakWindowState(inBreak: true, strict: true, fullscreen: true),
    );

    // Hold the escape for its full 3 seconds. The first pump only starts
    // the ticker; the hold duration elapses on the second.
    final gesture = await tester.press(find.byType(HoldToSkip));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await gesture.up();
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);
    expect(harness.overlay.state, BreakWindowState.normal);

    await cleanupHarness(tester, harness);
  });

  testWidgets('snoozing from the notification path dismisses the overlay '
      'and depletes the budget', (tester) async {
    final harness = TestHarness();
    await pumpToBreak(tester, harness);
    expect(find.byType(BreakOverlay), findsOneWidget);

    // The engine call is what the notification action triggers.
    expect(harness.engine.snooze(), isTrue);
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);
    expect(harness.overlay.state, BreakWindowState.normal);

    // Break returns after the 2-minute snooze; two snoozes remain.
    harness.advance(const Duration(minutes: 2, seconds: 5));
    await tester.pump();
    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(harness.engine.canSnooze, isTrue);

    await cleanupHarness(tester, harness);
  });

  // ---- Regression: the bug that trapped a real user ------------------------

  testWidgets('stepping away during a long break and coming back releases '
      'the window (regression: user was trapped in a full-screen, '
      'undecorated, unclosable window)', (tester) async {
    final harness = TestHarness();
    // Drive straight to the long break (it absorbs the micro one).
    await pumpToBreak(
      tester,
      harness,
      lead: const Duration(minutes: 50, seconds: 5),
    );

    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(harness.overlay.state.inBreak, isTrue);

    // A movement break is *meant* to get you away from the keyboard. Idling
    // past idleFireThreshold (2 min) used to make the engine credit an away
    // span from inside the break, ending the cycle without ever emitting
    // BreakCompleted — so nothing told the window to leave full-screen.
    harness.advance(
      const Duration(minutes: 3),
      const TickInput(idle: Duration(minutes: 3)),
    );
    await tester.pump();

    // Back at the keyboard. The break has run its course either way.
    harness.advance(const Duration(minutes: 3));
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);
    expect(
      harness.overlay.state,
      BreakWindowState.normal,
      reason: 'window must be restored — this is the trapped-user bug',
    );

    await cleanupHarness(tester, harness);
  });

  testWidgets('pausing mid-break releases the window', (tester) async {
    final harness = TestHarness();
    await pumpToBreak(tester, harness);
    expect(harness.overlay.state.inBreak, isTrue);

    harness.engine.setPausedByUser(true);
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);
    expect(harness.overlay.state, BreakWindowState.normal);

    await cleanupHarness(tester, harness);
  });
}
