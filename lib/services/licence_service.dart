// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/clock.dart';
import '../core/engine/engine.dart';
import '../core/licensing/entitlement.dart';
import '../data/settings_repository.dart';
import '../platform/interfaces/app_log.dart';
import '../platform/interfaces/licence_store.dart';

/// Keeps the engine's trial-ended lockout in step with what the user owns.
///
/// The Store is asked on start, every [recheckEvery], and after a purchase
/// or a restore. Its last answer is kept: an offline laptop must not lock out
/// someone who paid. A remembered Yearly plan is trusted for [offlineGrace]
/// without a fresh answer, a remembered Lifetime plan for good.
class LicenceService {
  LicenceService({
    required this.store,
    required this.settings,
    required this.engine,
    required this.clock,
    this.log = const NoAppLog(),
    this.recheckEvery = const Duration(hours: 1),
  });

  static const keyTrialStartedAt = 'trial_started_at';
  static const keyOwnedPlans = 'licence_owned_plans';
  static const keyOwnedCheckedAt = 'licence_checked_at';
  static const offlineGrace = Duration(days: 30);

  final LicenceStore store;
  final SettingsRepository settings;
  final BreakEngine engine;
  final Clock clock;
  final AppLog log;
  final Duration recheckEvery;

  final _changes = StreamController<Entitlement>.broadcast();
  Timer? _timer;
  Entitlement _current = const Unlimited();

  Entitlement get current => _current;
  Stream<Entitlement> get changes => _changes.stream;

  Future<void> start() async {
    if (!store.isStoreBuild) return;
    await refresh();
    _timer = Timer.periodic(recheckEvery, (_) => unawaited(refresh()));
  }

  /// Asks the Store again; also the "Restore purchase" action.
  Future<Entitlement> refresh() async {
    if (!store.isStoreBuild) return _current;
    final now = clock.now();
    final next = entitlementFrom(
      storeBuild: true,
      trialStartedAt: await _trialStart(now),
      now: now,
      owned: await _owned(now),
    );
    if (next != _current || next.runtimeType != _current.runtimeType) {
      log.info('licence ${_describe(next)}');
    }
    _current = next;
    engine.setLockedOut(!next.remindersAllowed);
    if (!_changes.isClosed) _changes.add(next);
    return next;
  }

  Future<PurchaseOutcome> buy(Plan plan) async {
    final outcome = await store.buy(plan);
    log.info('purchase ${plan.name}: ${outcome.name}');
    await refresh();
    return outcome;
  }

  Future<List<StoreOffer>> offers() => store.offers();

  Future<void> dispose() async {
    _timer?.cancel();
    await _changes.close();
  }

  Future<DateTime> _trialStart(DateTime now) async {
    final saved = DateTime.tryParse(
      await settings.readValue(keyTrialStartedAt) ?? '',
    );
    if (saved != null) return saved;
    await settings.writeValue(keyTrialStartedAt, now.toIso8601String());
    return now;
  }

  Future<Set<Plan>> _owned(DateTime now) async {
    try {
      final owned = await store.owned();
      await settings.writeValue(
        keyOwnedPlans,
        owned.map((p) => p.name).join(','),
      );
      await settings.writeValue(keyOwnedCheckedAt, now.toIso8601String());
      return owned;
    } on Object catch (e) {
      log.info('licence check failed, using the last answer: $e');
      return rememberedPlans(
        saved: await settings.readValue(keyOwnedPlans),
        checkedAt: DateTime.tryParse(
          await settings.readValue(keyOwnedCheckedAt) ?? '',
        ),
        now: now,
      );
    }
  }

  static String _describe(Entitlement e) => switch (e) {
    Unlimited() => 'unlimited',
    Trial(:final daysLeft) => 'trial, $daysLeft days left',
    Owned(:final plan) => 'owned ${plan.name}',
    TrialEnded() => 'trial ended',
  };
}

/// The plans last confirmed by the Store, as far as they can still be
/// trusted without a fresh answer.
Set<Plan> rememberedPlans({
  required String? saved,
  required DateTime? checkedAt,
  required DateTime now,
}) {
  final plans = {
    for (final name in (saved ?? '').split(','))
      for (final plan in Plan.values)
        if (plan.name == name) plan,
  };
  final fresh =
      checkedAt != null &&
      now.difference(checkedAt) <= LicenceService.offlineGrace;
  if (!fresh) plans.remove(Plan.yearly);
  return plans;
}
