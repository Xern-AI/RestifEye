// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/theme.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:restifeye/features/plans/plans.dart';
import 'package:restifeye/platform/fake/fake_licence_store.dart';
import 'package:restifeye/platform/interfaces/licence_store.dart';
import 'package:restifeye/services/licence_service.dart';
import 'package:restifeye/services/providers.dart';

void main() {
  final start = DateTime(2026, 10, 25, 9);

  Future<LicenceService> service(
    WidgetTester tester,
    FakeLicenceStore store, {
    Duration trialUsed = Duration.zero,
  }) async {
    final clock = ManualClock(startAt: start);
    final s = LicenceService(
      store: store,
      settings: SettingsRepository(AppDatabase.inMemory()),
      engine: BreakEngine(clock: clock, config: const BreakConfig()),
      clock: clock,
    );
    await tester.runAsync(() async {
      clock.advance(trialUsed);
      await s.refresh();
    });
    return s;
  }

  FakeLicenceStore trial15() =>
      FakeLicenceStore(trialEndsAt: start.add(const Duration(days: 15)));

  Future<void> pump(
    WidgetTester tester,
    LicenceService? s,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [licenceServiceProvider.overrideWithValue(s)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no banner and no licence row without a Store build', (
    tester,
  ) async {
    await pump(
      tester,
      null,
      const Column(children: [PlanBanner(), PlanSettingsTile()]),
    );
    expect(find.byType(Card), findsNothing);
    expect(find.text('Buy'), findsNothing);
  });

  testWidgets('the trial shows the days left, the price and Buy', (
    tester,
  ) async {
    final store = trial15()
      ..currentOffer = const StoreOffer(price: r'$19.99', fullPrice: r'$29.99');
    final s = await service(tester, store, trialUsed: const Duration(days: 4));
    await pump(
      tester,
      s,
      const Column(children: [PlanBanner(), PlanSettingsTile()]),
    );
    expect(find.text('Free trial: 11 days left'), findsOneWidget);
    expect(find.text('11 days left'), findsOneWidget);
    expect(find.textContaining(r'$19.99'), findsOneWidget);
    expect(find.textContaining(r'$29.99'), findsOneWidget);
    expect(find.text('Buy'), findsNWidgets(2));
  });

  testWidgets('after the trial: breaks paused, history kept, Buy unlocks', (
    tester,
  ) async {
    final s = await service(
      tester,
      trial15(),
      trialUsed: const Duration(days: 16),
    );
    await pump(tester, s, const PlanBanner());
    expect(find.text('Your free trial has ended'), findsOneWidget);
    expect(find.textContaining('history is all still here'), findsOneWidget);
    expect(find.text('Pay once, yours to keep.'), findsOneWidget);

    await tester.tap(find.text('Buy'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Thank you! RestifEye is yours to keep.'), findsOneWidget);
    expect(find.text('Your free trial has ended'), findsNothing);
  });

  testWidgets('a bought copy says thank you and offers nothing', (
    tester,
  ) async {
    final store = trial15();
    final s = await service(tester, store);
    await tester.runAsync(s.buy);
    await pump(
      tester,
      s,
      const Column(children: [PlanBanner(), PlanSettingsTile()]),
    );
    expect(find.text('Full version'), findsOneWidget);
    expect(find.text('Bought. Thank you!'), findsOneWidget);
    expect(find.text('Buy'), findsNothing);
  });

  testWidgets('a failed purchase says what to check', (tester) async {
    final store = trial15()..nextOutcome = PurchaseOutcome.failed;
    final s = await service(tester, store);
    await pump(tester, s, const PlanBanner());
    await tester.tap(find.text('Buy'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('signed in to the Store'), findsOneWidget);
  });
}
