// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/app/app.dart';
import 'package:restifeye/core/engine/events.dart';
import 'package:restifeye/core/models/activity.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/data/activity_repository.dart';
import 'package:restifeye/data/break_log_repository.dart';
import 'package:restifeye/features/dashboard/day_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/overrides.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(harness.wrap(const RestifEyeApp()));
    await tester.pump();
  }

  group('AppShell navigation', () {
    testWidgets(
      'shows a navigation rail at desktop width and switches screens',
      (tester) async {
        await pumpApp(tester, const Size(1280, 800));

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Eye breaks'), findsOneWidget);
        expect(find.text('Strict mode'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.insights_outlined));
        await tester.pumpAndSettle();
        expect(find.textContaining('trends will appear'), findsOneWidget);

        await cleanupHarness(tester, harness);
      },
    );

    testWidgets('shows a bottom navigation bar at narrow width', (
      tester,
    ) async {
      await pumpApp(tester, const Size(500, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await cleanupHarness(tester, harness);
    });
  });

  group('Dashboard live data', () {
    testWidgets('renders the engine countdown', (tester) async {
      await pumpApp(tester, const Size(1280, 800));
      harness.advance(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Next eye break'), findsOneWidget);
      expect(find.text('19:59'), findsOneWidget);

      await cleanupHarness(tester, harness);
    });

    testWidgets('renders today stats from the database, including the idle, '
        'away and watch time that used to be discarded', (tester) async {
      final day = DateTime.now();
      final activity = ActivityRepository(harness.db);
      DateTime at(int hour, [int minute = 0]) =>
          DateTime(day.year, day.month, day.day, hour, minute);

      // 1h20m hands-on, 40m idle at the desk, 30m locked away, 25m watching.
      await activity.insertSlice(
        ActivitySlice(start: at(9), end: at(10, 20), kind: SliceKind.active),
      );
      await activity.insertSlice(
        ActivitySlice(start: at(10, 20), end: at(11), kind: SliceKind.idle),
      );
      await activity.insertSlice(
        ActivitySlice(start: at(11), end: at(11, 30), kind: SliceKind.locked),
      );
      await activity.insertSlice(
        ActivitySlice(
          start: at(11, 30),
          end: at(11, 55),
          kind: SliceKind.watching,
        ),
      );

      final breakLog = BreakLogRepository(harness.db);
      await breakLog.record(BreakCompleted(day, BreakKind.micro));
      await breakLog.record(
        BreakCredited(
          day,
          BreakKind.long,
          BreakOutcome.creditedLock,
          const Duration(minutes: 6),
        ),
      );

      await pumpApp(tester, const Size(1280, 800));
      await tester.pump(); // stream deliveries

      // At computer now includes watching: 1h20 + 40m + 25m.
      expect(find.text('2h 25m'), findsOneWidget);
      expect(find.text('40m'), findsOneWidget); // idle
      expect(find.text('30m'), findsOneWidget); // away
      expect(find.text('25m'), findsOneWidget); // watching
      // Hands-on share of time at the computer: 80 min of 145.
      expect(find.textContaining('55%'), findsOneWidget);
      // Active time and longest unbroken stretch are the same single slice.
      expect(find.text('1h 20m'), findsNWidgets(2));

      // The day shape knows which hours the work landed in.
      expect(find.byType(DayShape), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget); // busiest hour

      await tester.scrollUntilVisible(find.text('Breaks'), 300);
      expect(find.text('Followed through'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget); // nothing escaped

      await cleanupHarness(tester, harness);
    });
  });
}
