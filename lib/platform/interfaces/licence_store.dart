// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';

/// A plan as the Store sells it right now, prices already formatted in the
/// buyer's currency.
class StoreOffer {
  const StoreOffer({required this.plan, required this.price, this.fullPrice});

  final Plan plan;
  final String price;

  /// The usual price while a sale is on (shown crossed out), else null.
  final String? fullPrice;
}

enum PurchaseOutcome { purchased, alreadyOwned, cancelled, failed }

/// Where plans are bought and owned plans are looked up.
abstract interface class LicenceStore {
  /// Whether this copy came from the Store and is therefore licensed.
  bool get isStoreBuild;

  /// The plans this user owns now. Throws when the Store cannot answer
  /// (offline, Store app broken), so the caller can fall back to what it
  /// last knew rather than locking a paying user out.
  Future<Set<Plan>> owned();

  /// Current prices. Empty when the Store cannot answer.
  Future<List<StoreOffer>> offers();

  Future<PurchaseOutcome> buy(Plan plan);
}

/// Linux and the Windows test zips: nothing to license.
class NoLicenceStore implements LicenceStore {
  const NoLicenceStore();

  @override
  bool get isStoreBuild => false;

  @override
  Future<Set<Plan>> owned() async => const {};

  @override
  Future<List<StoreOffer>> offers() async => const [];

  @override
  Future<PurchaseOutcome> buy(Plan plan) async => PurchaseOutcome.failed;
}
