// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/licensing/entitlement.dart';
import '../interfaces/licence_store.dart';
import 'windows_runner.dart';

/// The Microsoft Store, through the runner's `Windows.Services.Store` calls.
/// The app itself is the product: a paid app with the Store's free trial.
class WindowsLicenceStore implements LicenceStore {
  WindowsLicenceStore(this.runner, {required this.isStoreBuild});

  final WindowsRunner runner;

  @override
  final bool isStoreBuild;

  /// The app's Store ID, learnt from the last offer query; a purchase
  /// needs it.
  String? _storeId;

  @override
  Future<StoreLicence> licence() async {
    final reply = await runner.storeLicence();
    if (reply['ok'] != true) {
      throw StateError('Store licence: ${reply['error'] ?? 'no answer'}');
    }
    return licenceFromReply(reply);
  }

  @override
  Future<StoreOffer?> offer() async {
    final reply = await runner.storeOffer();
    if (reply['ok'] != true) return null;
    final id = reply['storeId'] as String? ?? '';
    if (id.isNotEmpty) _storeId = id;
    final full = reply['fullPrice'] as String? ?? '';
    return StoreOffer(
      price: reply['price'] as String? ?? '',
      fullPrice: full.isEmpty ? null : full,
    );
  }

  @override
  Future<PurchaseOutcome> buy() async {
    if (_storeId == null) await offer();
    final storeId = _storeId;
    if (storeId == null) return PurchaseOutcome.failed;
    final reply = await runner.storePurchase(storeId);
    return PurchaseOutcome.values.firstWhere(
      (o) => o.name == reply['status'],
      orElse: () => PurchaseOutcome.failed,
    );
  }
}

StoreLicence licenceFromReply(Map<Object?, Object?> reply) {
  final trial = reply['trial'] == true;
  final endsMs = (reply['trialEndsMs'] as num?)?.toInt() ?? 0;
  return StoreLicence(
    fromStore: reply['fromStore'] == true,
    active: reply['active'] == true,
    trial: trial,
    trialEndsAt: trial && endsMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(endsMs)
        : null,
  );
}
