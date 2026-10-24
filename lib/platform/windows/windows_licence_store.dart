// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';
import '../interfaces/licence_store.dart';
import 'windows_runner.dart';

/// Product IDs of the two add-ons. Partner Center must use exactly these:
/// the app finds its plans by them, not by Store ID.
const planTokens = {
  Plan.yearly: 'restifeye.yearly',
  Plan.lifetime: 'restifeye.lifetime',
};

/// The Microsoft Store, through the runner's `Windows.Services.Store` calls.
class WindowsLicenceStore implements LicenceStore {
  WindowsLicenceStore(this.runner, {required this.isStoreBuild});

  final WindowsRunner runner;

  @override
  final bool isStoreBuild;

  /// Store IDs learnt from the last offers query; a purchase needs one.
  final Map<Plan, String> _storeIds = {};

  @override
  Future<Set<Plan>> owned() async {
    final reply = await runner.storeOwned();
    if (reply['ok'] != true) {
      throw StateError('Store licence: ${reply['error'] ?? 'no answer'}');
    }
    return plansFromTokens((reply['tokens'] as List?)?.cast<String>() ?? []);
  }

  @override
  Future<List<StoreOffer>> offers() async {
    final reply = await runner.storeOffers();
    if (reply['ok'] != true) return const [];
    final offers = <StoreOffer>[];
    for (final raw in (reply['offers'] as List?) ?? const []) {
      final item = (raw as Map).cast<Object?, Object?>();
      final plan = planFor(item['token'] as String? ?? '');
      if (plan == null) continue;
      _storeIds[plan] = item['storeId'] as String? ?? '';
      final full = item['fullPrice'] as String? ?? '';
      offers.add(
        StoreOffer(
          plan: plan,
          price: item['price'] as String? ?? '',
          fullPrice: full.isEmpty ? null : full,
        ),
      );
    }
    offers.sort((a, b) => a.plan.index.compareTo(b.plan.index));
    return offers;
  }

  @override
  Future<PurchaseOutcome> buy(Plan plan) async {
    if (!_storeIds.containsKey(plan)) await offers();
    final storeId = _storeIds[plan];
    if (storeId == null || storeId.isEmpty) return PurchaseOutcome.failed;
    final reply = await runner.storePurchase(storeId);
    return PurchaseOutcome.values.firstWhere(
      (o) => o.name == reply['status'],
      orElse: () => PurchaseOutcome.failed,
    );
  }
}

Plan? planFor(String token) {
  for (final entry in planTokens.entries) {
    if (entry.value == token) return entry.key;
  }
  return null;
}

Set<Plan> plansFromTokens(Iterable<String> tokens) => {
  for (final token in tokens) ?planFor(token),
};
