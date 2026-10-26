// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/interfaces/licence_store.dart';
import 'package:restifeye/platform/windows/windows_licence_store.dart';
import 'package:restifeye/platform/windows/windows_runner.dart';
import 'package:restifeye/platform/windows/windows_startup_task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, Object?> replies;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    replies = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(WindowsRunner.channelName),
          (call) async {
            calls.add(call);
            return replies[call.method];
          },
        );
  });

  WindowsLicenceStore store() =>
      WindowsLicenceStore(WindowsRunner(), isStoreBuild: true);

  test('a trial licence carries its end date', () async {
    final ends = DateTime.utc(2026, 11, 9, 9);
    replies['storeLicence'] = {
      'ok': true,
      'active': true,
      'trial': true,
      'fromStore': true,
      'trialEndsMs': ends.millisecondsSinceEpoch,
      'error': '',
    };
    final licence = await store().licence();
    expect(licence.fromStore, isTrue);
    expect(licence.trial, isTrue);
    expect(licence.trialEndsAt?.toUtc(), ends);
  });

  test('a full licence has no end date', () {
    final licence = licenceFromReply({
      'ok': true,
      'active': true,
      'trial': false,
      'fromStore': true,
      'trialEndsMs': 0,
    });
    expect(licence.active, isTrue);
    expect(licence.trial, isFalse);
    expect(licence.trialEndsAt, isNull);
  });

  test('a Store that cannot answer throws, so the last answer is kept', () {
    replies['storeLicence'] = {'ok': false, 'error': 'offline'};
    expect(store().licence(), throwsStateError);
  });

  test('the offer carries the Store price and the sale price', () async {
    replies['storeOffer'] = {
      'ok': true,
      'storeId': '9APP',
      'price': r'$19.99',
      'fullPrice': r'$29.99',
      'error': '',
    };
    final offer = await store().offer();
    expect(offer?.price, r'$19.99');
    expect(offer?.fullPrice, r'$29.99');

    replies['storeOffer'] = {'ok': false, 'error': 'offline'};
    expect(await store().offer(), isNull);
  });

  test('buying uses the app Store ID and maps the outcome', () async {
    replies['storeOffer'] = {
      'ok': true,
      'storeId': '9APP',
      'price': r'$29.99',
      'fullPrice': '',
    };
    replies['storePurchase'] = {'status': 'cancelled', 'error': ''};
    expect(await store().buy(), PurchaseOutcome.cancelled);
    final purchase = calls.firstWhere((c) => c.method == 'storePurchase');
    expect((purchase.arguments as Map)['storeId'], '9APP');

    replies['storeOffer'] = {'ok': false, 'error': 'offline'};
    expect(await store().buy(), PurchaseOutcome.failed);
  });

  test('the startup task counts as on only when Windows says so', () {
    expect(startupTaskOn('enabled'), isTrue);
    expect(startupTaskOn('enabledByPolicy'), isTrue);
    expect(startupTaskOn('disabledByUser'), isFalse);
    expect(startupTaskOn('error'), isFalse);
  });
}
