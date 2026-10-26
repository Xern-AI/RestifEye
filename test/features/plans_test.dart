// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/theme.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/licensing/entitlement.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:restifeye/features/plans/plans.dart';
import 'package:restifeye/platform/fake/fake_licence_store.dart';
import 'package:restifeye/platform/interfaces/licence_store.dart';
import 'package:restifeye/services/licence_service.dart';
import 'package:restifeye/services/providers.dart';

void main() {
  Future<LicenceService> service(
    WidgetTester tester,
    FakeLicenceStore store, {
    Duration trialUsed = Duration.zero,
  }) async {
    final clock = ManualClock(startAt: DateTime(2026, 10, 25, 9));
    final s = LicenceService(
      store: store,
      settings: SettingsRepository(AppDatabase.inMemory()),
      engine: BreakEngine(clock: clock, config: const BreakConfig()),
      clock: clock,
    );
    await tester.runAsync(() async {
      await s.refresh();
      clock.advance(trialUsed);
      await s.refresh();
    });
    return s;
  }

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

  final offers = [
    const StoreOffer(plan: Plan.yearly, price: r'$11.99'),
    const StoreOffer(
      plan: Plan.lifetime,
      price: r'$29.99',
      fullPrice: r'$39.99',
    ),
  ];

  testWidgets('no banner and no plan row without a Store build', (
    tester,
  ) async {
    await pump(
      tester,
      null,
      const Column(children: [PlanBanner(), PlanSettingsTile()]),
    );
    expect(find.byType(Card), findsNothing);
    expect(find.text('Plan'), findsNothing);
  });

  testWidgets('the trial shows the days left and a way to choose', (
    tester,
  ) async {
    final s = await service(
      tester,
      FakeLicenceStore(),
      trialUsed: const Duration(days: 4),
    );
    await pump(
      tester,
      s,
      const Column(children: [PlanBanner(), PlanSettingsTile()]),
    );
    expect(find.text('Free trial: 10 days left'), findsOneWidget);
    expect(find.text('Free trial, 10 days left'), findsOneWidget);
  });

  testWidgets('after the trial: breaks paused, history kept, plans offered', (
    tester,
  ) async {
    final store = FakeLicenceStore()..currentOffers = offers;
    final s = await service(tester, store, trialUsed: const Duration(days: 15));
    await pump(tester, s, const PlanBanner());
    expect(find.text('Your free trial has ended'), findsOneWidget);
    expect(find.textContaining('history is all still here'), findsOneWidget);

    await tester.tap(find.text('Choose a plan'));
    await tester.pumpAndSettle();
    expect(find.text(r'$11.99'), findsOneWidget);
    expect(find.text(r'$29.99'), findsOneWidget);
    expect(find.text(r'$39.99'), findsOneWidget, reason: 'sale price struck');

    await tester.tap(find.text('Buy Lifetime'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Thank you! RestifEye is unlocked.'), findsOneWidget);
    expect(find.text('Your free trial has ended'), findsNothing);
  });

  testWidgets('a Store that does not answer offers a retry', (tester) async {
    final s = await service(tester, FakeLicenceStore());
    await pump(tester, s, const PlanSheet());
    expect(find.textContaining('did not answer'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
