// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/core/engine/engine.dart';
import 'package:restifeye/core/engine/phase.dart';
import 'package:restifeye/core/licensing/entitlement.dart';
import 'package:restifeye/core/models/break_config.dart';
import 'package:restifeye/data/database.dart';
import 'package:restifeye/data/settings_repository.dart';
import 'package:restifeye/platform/fake/fake_licence_store.dart';
import 'package:restifeye/platform/interfaces/licence_store.dart';
import 'package:restifeye/services/licence_service.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;
  late ManualClock clock;
  late BreakEngine engine;
  late FakeLicenceStore store;

  setUp(() {
    db = AppDatabase.inMemory();
    settings = SettingsRepository(db);
    clock = ManualClock(startAt: DateTime(2026, 10, 25, 9));
    engine = BreakEngine(clock: clock, config: const BreakConfig());
    store = FakeLicenceStore();
  });

  tearDown(() => db.close());

  LicenceService service() => LicenceService(
    store: store,
    settings: settings,
    engine: engine,
    clock: clock,
  );

  bool lockedOut() =>
      engine.phase is Paused &&
      (engine.phase as Paused).reason == PauseReason.trialEnded;

  test('not a Store build: nothing is checked and nothing is locked', () async {
    store = FakeLicenceStore(isStoreBuild: false);
    final s = service();
    await s.start();
    expect(s.current, const Unlimited());
    expect(await settings.readValue(LicenceService.keyTrialStartedAt), isNull);
    expect(lockedOut(), isFalse);
    await s.dispose();
  });

  test('the trial starts on first run and survives a restart', () async {
    final first = service();
    await first.start();
    expect(first.current, const Trial(14));
    await first.dispose();

    clock.advance(const Duration(days: 5));
    final again = service();
    await again.start();
    expect(again.current, const Trial(9));
    await again.dispose();
  });

  test('the trial ending locks reminders; buying unlocks them', () async {
    final s = service();
    await s.start();
    clock.advance(const Duration(days: 14));
    expect(await s.refresh(), const TrialEnded());
    expect(lockedOut(), isTrue);

    expect(await s.buy(Plan.lifetime), PurchaseOutcome.purchased);
    expect(s.current, const Owned(Plan.lifetime));
    expect(lockedOut(), isFalse);
    await s.dispose();
  });

  test('a cancelled purchase changes nothing', () async {
    final s = service();
    await s.start();
    clock.advance(const Duration(days: 20));
    await s.refresh();
    store.nextOutcome = PurchaseOutcome.cancelled;
    expect(await s.buy(Plan.yearly), PurchaseOutcome.cancelled);
    expect(s.current, const TrialEnded());
    await s.dispose();
  });

  test(
    'offline keeps the last answer: Lifetime for good, Yearly 30 days',
    () async {
      store.ownedPlans = {Plan.yearly};
      final s = service();
      await s.start();
      expect(s.current, const Owned(Plan.yearly));

      store.offline = true;
      clock.advance(const Duration(days: 29));
      expect(await s.refresh(), const Owned(Plan.yearly));
      clock.advance(const Duration(days: 2));
      expect(await s.refresh(), const TrialEnded());
      await s.dispose();
    },
  );

  test('remembered plans: unknown names are ignored, Lifetime never ages', () {
    final now = DateTime(2027, 1, 1);
    expect(
      rememberedPlans(saved: 'lifetime,bogus', checkedAt: null, now: now),
      {Plan.lifetime},
    );
    expect(
      rememberedPlans(
        saved: 'yearly',
        checkedAt: now.subtract(const Duration(days: 31)),
        now: now,
      ),
      isEmpty,
    );
    expect(rememberedPlans(saved: null, checkedAt: null, now: now), isEmpty);
  });
}
