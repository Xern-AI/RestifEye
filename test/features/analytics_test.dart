// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/theme.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/rollup_repository.dart';
import 'package:restifeye/features/analytics/analytics_screen.dart';
import 'package:restifeye/services/providers.dart';

void main() {
  late AppDatabase db;
  final today = DateTime(2026, 6, 15);

  setUp(() => db = AppDatabase.inMemory());

  Future<void> seed(int daysBack, {int escaped = 0, int? lateHour}) async {
    final rollups = RollupRepository(db);
    for (var back = daysBack; back >= 1; back--) {
      final day = DateTime(today.year, today.month, today.day - back);
      await rollups.upsert((
        day: day,
        screen: const Duration(hours: 5),
        idle: const Duration(hours: 1),
        watch: const Duration(minutes: 30),
        away: const Duration(minutes: 45),
        longestStretch: const Duration(minutes: 55),
        focusRuns: 3,
        firstActivityMinute: 9 * 60,
        lastActivityMinute: 18 * 60,
        activeByHour: [
          for (var h = 0; h < 24; h++)
            if (h == lateHour) 3600 else if (h >= 9 && h < 14) 3600 else 0,
        ],
        completed: 10,
        credited: 1,
        escaped: escaped,
        snoozes: 2,
      ));
    }
  }

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1100, 2400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          wallClockProvider.overrideWithValue(() => today),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AnalyticsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
  }

  testWidgets('invites patience before there is anything to show', (
    tester,
  ) async {
    await pump(tester);
    expect(find.textContaining('trends will appear'), findsOneWidget);
    await settle(tester);
  });

  // Every chart on this screen lays out at several widths; the heatmap's
  // hour labels asserted the first time they met an unbounded column.
  testWidgets('renders every chart without a layout error', (tester) async {
    await seed(20);
    await pump(tester);

    expect(find.text('Rest score'), findsOneWidget);
    expect(find.text('Where each day went'), findsOneWidget);
    expect(find.text('Breaks actually taken'), findsOneWidget);
    expect(find.text('When you work'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);

    await settle(tester);
  });

  testWidgets('survives a narrow window', (tester) async {
    await seed(20);
    await pump(tester, size: const Size(480, 2600));
    expect(find.text('Rest score'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('scores the period and names what to improve', (tester) async {
    await seed(20, escaped: 40); // most due breaks escaped
    await pump(tester);

    expect(find.textContaining('of due breaks rested'), findsOneWidget);
    expect(
      find.textContaining('Biggest gain available', findRichText: true),
      findsOneWidget,
    );
    // The advice names the component actually costing the most points.
    expect(
      find.textContaining('coming due and going untaken', findRichText: true),
      findsOneWidget,
    );

    await settle(tester);
  });

  testWidgets('asks for more days before scoring', (tester) async {
    await seed(2);
    await pump(tester);
    expect(find.textContaining('needs at least three days'), findsOneWidget);
    await settle(tester);
  });
}
