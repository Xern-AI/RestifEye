// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';
import '../interfaces/licence_store.dart';

/// A Store for tests: owned plans, offers and outcomes are set directly.
class FakeLicenceStore implements LicenceStore {
  FakeLicenceStore({this.isStoreBuild = true});

  @override
  final bool isStoreBuild;

  Set<Plan> ownedPlans = {};
  bool offline = false;
  PurchaseOutcome nextOutcome = PurchaseOutcome.purchased;
  List<StoreOffer> currentOffers = const [];

  @override
  Future<Set<Plan>> owned() async {
    if (offline) throw StateError('offline');
    return {...ownedPlans};
  }

  @override
  Future<List<StoreOffer>> offers() async => currentOffers;

  @override
  Future<PurchaseOutcome> buy(Plan plan) async {
    if (nextOutcome == PurchaseOutcome.purchased) ownedPlans.add(plan);
    return nextOutcome;
  }
}
