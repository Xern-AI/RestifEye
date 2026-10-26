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
  final start = DateTime(2026, 10, 25, 9);
  late AppDatabase db;
  late SettingsRepository settings;
  late ManualClock clock;
  late BreakEngine engine;
  late FakeLicenceStore store;

  setUp(() {
    db = AppDatabase.inMemory();
    settings = SettingsRepository(db);
    clock = ManualClock(startAt: start);
    engine = BreakEngine(clock: clock, config: const BreakConfig());
    store = FakeLicenceStore(trialEndsAt: start.add(const Duration(days: 15)));
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
    expect(await settings.readValue(LicenceService.keyLicence), isNull);
    expect(lockedOut(), isFalse);
    await s.dispose();
  });

  test('the Store trial counts down as the clock moves', () async {
    final s = service();
    await s.start();
    expect(s.current, const Trial(15));
    clock.advance(const Duration(days: 5));
    expect(await s.refresh(), const Trial(10));
    await s.dispose();
  });

  test('the trial ending locks reminders; buying unlocks them', () async {
    final s = service();
    await s.start();
    clock.advance(const Duration(days: 15));
    expect(await s.refresh(), const TrialEnded());
    expect(lockedOut(), isTrue);

    expect(await s.buy(), PurchaseOutcome.purchased);
    expect(s.current, const Owned());
    expect(lockedOut(), isFalse);
    await s.dispose();
  });

  test('a cancelled purchase changes nothing', () async {
    final s = service();
    await s.start();
    clock.advance(const Duration(days: 20));
    await s.refresh();
    store.nextOutcome = PurchaseOutcome.cancelled;
    expect(await s.buy(), PurchaseOutcome.cancelled);
    expect(s.current, const TrialEnded());
    await s.dispose();
  });

  test('offline: a bought copy stays unlocked for good', () async {
    store.current = const StoreLicence(
      fromStore: true,
      active: true,
      trial: false,
    );
    final s = service();
    await s.start();
    store.offline = true;
    clock.advance(const Duration(days: 400));
    expect(await s.refresh(), const Owned());
    await s.dispose();
  });

  test('offline: a remembered trial still ends on its date', () async {
    final s = service();
    await s.start();
    store.offline = true;
    clock.advance(const Duration(days: 14));
    expect(await s.refresh(), const Trial(1));
    clock.advance(const Duration(days: 1));
    expect(await s.refresh(), const TrialEnded());
    await s.dispose();
  });

  test('a Store that has never answered locks nothing', () async {
    store.offline = true;
    final s = service();
    await s.start();
    expect(s.current, const Unlimited());
    expect(lockedOut(), isFalse);
    await s.dispose();
  });

  test('the saved answer round-trips', () {
    final ends = DateTime.utc(2026, 11, 9, 3, 30);
    for (final licence in [
      const StoreLicence(fromStore: false, active: true, trial: false),
      const StoreLicence(fromStore: true, active: true, trial: false),
      const StoreLicence(fromStore: true, active: false, trial: true),
      StoreLicence(
        fromStore: true,
        active: true,
        trial: true,
        trialEndsAt: ends,
      ),
    ]) {
      final back = decodeLicence(encodeLicence(licence))!;
      expect(back.fromStore, licence.fromStore);
      expect(back.active, licence.active);
      expect(back.trial, licence.trial);
      expect(back.trialEndsAt?.toUtc(), licence.trialEndsAt?.toUtc());
    }
    expect(decodeLicence(null), isNull);
    expect(decodeLicence('trial:not-a-date'), isNull);
    expect(decodeLicence('lifetime'), isNull);
  });
}
