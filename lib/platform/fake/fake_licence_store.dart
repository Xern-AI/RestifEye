// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';
import '../interfaces/licence_store.dart';

/// A Store for tests: the licence, price and outcomes are set directly.
class FakeLicenceStore implements LicenceStore {
  FakeLicenceStore({this.isStoreBuild = true, DateTime? trialEndsAt})
    : current = StoreLicence(
        fromStore: true,
        active: true,
        trial: true,
        trialEndsAt: trialEndsAt ?? DateTime(2026, 11, 9, 9),
      );

  @override
  final bool isStoreBuild;

  StoreLicence current;
  bool offline = false;
  PurchaseOutcome nextOutcome = PurchaseOutcome.purchased;
  StoreOffer? currentOffer;

  @override
  Future<StoreLicence> licence() async {
    if (offline) throw StateError('offline');
    return current;
  }

  @override
  Future<StoreOffer?> offer() async => currentOffer;

  @override
  Future<PurchaseOutcome> buy() async {
    if (nextOutcome == PurchaseOutcome.purchased) {
      current = const StoreLicence(fromStore: true, active: true, trial: false);
    }
    return nextOutcome;
  }
}
