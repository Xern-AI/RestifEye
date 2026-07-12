import 'package:breaktime/app/app.dart';
import 'package:breaktime/core/models/break_config.dart';
import 'package:breaktime/features/breaks/break_overlay.dart';
import 'package:breaktime/features/breaks/hold_to_skip.dart';
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
    await tester.pumpWidget(harness.wrap(const BreakTimeApp()));
    await tester.pump();
    harness.advance(lead);
    await tester.pump();
  }

  testWidgets('overlay appears when a break starts, with snooze available', (
    tester,
  ) async {
    final harness = TestHarness();
    await pumpToBreak(tester, harness);

    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(find.text('Eye break'), findsOneWidget);
    expect(find.textContaining('Snooze (3 left)'), findsOneWidget);
    expect(find.byType(HoldToSkip), findsOneWidget);
    expect(harness.overlay.calls, contains('enter(strict: false)'));

    await cleanupHarness(tester, harness);
  });

  testWidgets('strict break hides snooze and holding skip escapes it', (
    tester,
  ) async {
    final harness = TestHarness(config: const BreakConfig(snoozeBudget: 0));
    await pumpToBreak(tester, harness);

    expect(find.byType(BreakOverlay), findsOneWidget);
    expect(find.textContaining('Snooze'), findsNothing);
    expect(harness.overlay.calls, contains('enter(strict: true)'));

    // Hold the escape for its full 3 seconds. The first pump only starts
    // the ticker; the hold duration elapses on the second.
    final gesture = await tester.press(find.byType(HoldToSkip));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await gesture.up();
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);
    expect(harness.overlay.calls, contains('exit'));

    await cleanupHarness(tester, harness);
  });

  testWidgets('snoozing dismisses the overlay and depletes the budget', (
    tester,
  ) async {
    final harness = TestHarness();
    await pumpToBreak(tester, harness);

    await tester.tap(find.textContaining('Snooze'));
    await tester.pump();

    expect(find.byType(BreakOverlay), findsNothing);

    // Break returns after the 2-minute snooze with one fewer snooze left.
    harness.advance(const Duration(minutes: 2, seconds: 5));
    await tester.pump();
    expect(find.textContaining('Snooze (2 left)'), findsOneWidget);

    await cleanupHarness(tester, harness);
  });
}
