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

/// Keeps the engine's trial-ended lockout in step with the app's Store
/// licence.
///
/// The Store is asked on start, every [recheckEvery] (so a purchase made in
/// the Store app, or the trial running out, is noticed in a running copy),
/// and after a purchase. Its last answer is kept: an offline laptop must
/// not lock out someone who paid, and a remembered trial still ends on its
/// date.
class LicenceService {
  LicenceService({
    required this.store,
    required this.settings,
    required this.engine,
    required this.clock,
    this.log = const NoAppLog(),
    this.recheckEvery = const Duration(minutes: 10),
  });

  static const keyLicence = 'store_licence';

  final LicenceStore store;
  final SettingsRepository settings;
  final BreakEngine engine;
  final Clock clock;
  final AppLog log;
  final Duration recheckEvery;

  final _changes = StreamController<Entitlement>.broadcast();
  Timer? _timer;
  Entitlement _current = const Unlimited();
  bool _answered = false;

  Entitlement get current => _current;
  Stream<Entitlement> get changes => _changes.stream;

  Future<void> start() async {
    if (!store.isStoreBuild) return;
    await refresh();
    _timer = Timer.periodic(recheckEvery, (_) => unawaited(refresh()));
  }

  Future<Entitlement> refresh() async {
    if (!store.isStoreBuild) return _current;
    final now = clock.now();
    final next = entitlementFrom(
      storeBuild: true,
      licence: await _licence(),
      now: now,
    );
    if (!_answered ||
        next != _current ||
        next.runtimeType != _current.runtimeType) {
      log.info('licence ${_describe(next)}');
    }
    _answered = true;
    _current = next;
    engine.setLockedOut(!next.remindersAllowed);
    if (!_changes.isClosed) _changes.add(next);
    return next;
  }

  Future<PurchaseOutcome> buy() async {
    final outcome = await store.buy();
    log.info('purchase: ${outcome.name}');
    await refresh();
    return outcome;
  }

  Future<StoreOffer?> offer() => store.offer();

  Future<void> dispose() async {
    _timer?.cancel();
    await _changes.close();
  }

  Future<StoreLicence?> _licence() async {
    try {
      final licence = await store.licence();
      await settings.writeValue(keyLicence, encodeLicence(licence));
      return licence;
    } on Object catch (e) {
      log.info('licence check failed, using the last answer: $e');
      return decodeLicence(await settings.readValue(keyLicence));
    }
  }

  static String _describe(Entitlement e) => switch (e) {
    Unlimited() => 'unlimited',
    Trial(:final daysLeft) => 'trial, $daysLeft days left',
    Owned() => 'owned',
    TrialEnded() => 'trial ended',
  };
}

/// The Store's last answer as one settings value: `owned`, `ended`,
/// `trial:<end>` or `none` (not acquired from the Store).
String encodeLicence(StoreLicence licence) {
  if (!licence.fromStore) return 'none';
  if (!licence.trial) return licence.active ? 'owned' : 'ended';
  final ends = licence.trialEndsAt;
  if (!licence.active || ends == null) return 'ended';
  return 'trial:${ends.toUtc().toIso8601String()}';
}

StoreLicence? decodeLicence(String? saved) {
  if (saved == null) return null;
  if (saved == 'none') {
    return const StoreLicence(fromStore: false, active: true, trial: false);
  }
  if (saved == 'owned') {
    return const StoreLicence(fromStore: true, active: true, trial: false);
  }
  if (saved == 'ended') {
    return const StoreLicence(fromStore: true, active: false, trial: true);
  }
  if (saved.startsWith('trial:')) {
    final ends = DateTime.tryParse(saved.substring('trial:'.length));
    if (ends == null) return null;
    return StoreLicence(
      fromStore: true,
      active: true,
      trial: true,
      trialEndsAt: ends.toLocal(),
    );
  }
  return null;
}
