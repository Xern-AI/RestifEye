// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';

/// The app as the Store sells it right now, prices already formatted in the
/// buyer's currency.
class StoreOffer {
  const StoreOffer({required this.price, this.fullPrice});

  final String price;

  /// The usual price while a sale is on (shown crossed out), else null.
  final String? fullPrice;
}

enum PurchaseOutcome { purchased, alreadyOwned, cancelled, failed }

/// Where the app's licence is read and the app is bought.
abstract interface class LicenceStore {
  /// Whether this copy runs from the Store's package and is therefore
  /// licensed.
  bool get isStoreBuild;

  /// This app's licence now. Throws when the Store cannot answer (offline,
  /// Store app broken), so the caller can fall back to what it last knew
  /// rather than locking a paying user out.
  Future<StoreLicence> licence();

  /// The current price, or null when the Store cannot answer.
  Future<StoreOffer?> offer();

  /// Shows the Store's own purchase window for the full app.
  Future<PurchaseOutcome> buy();
}

/// Linux and the Windows test zips: nothing to license.
class NoLicenceStore implements LicenceStore {
  const NoLicenceStore();

  @override
  bool get isStoreBuild => false;

  @override
  Future<StoreLicence> licence() async =>
      const StoreLicence(fromStore: false, active: true, trial: false);

  @override
  Future<StoreOffer?> offer() async => null;

  @override
  Future<PurchaseOutcome> buy() async => PurchaseOutcome.failed;
}
