// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/licensing/entitlement.dart';
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

  test('plans are found by product ID; anything else is ignored', () {
    expect(plansFromTokens(['restifeye.lifetime', 'other.addon']), {
      Plan.lifetime,
    });
    expect(planFor('restifeye.yearly'), Plan.yearly);
    expect(planFor('restifeye.monthly'), isNull);
  });

  test('owned plans come from active add-on licences', () async {
    replies['storeOwned'] = {
      'ok': true,
      'tokens': ['restifeye.yearly'],
      'error': '',
    };
    expect(await store().owned(), {Plan.yearly});
  });

  test('a Store that cannot answer throws, so the last answer is kept', () {
    replies['storeOwned'] = {'ok': false, 'tokens': [], 'error': 'offline'};
    expect(store().owned(), throwsStateError);
  });

  test('offers carry Store prices and a sale price, in plan order', () async {
    replies['storeOffers'] = {
      'ok': true,
      'error': '',
      'offers': [
        {
          'token': 'restifeye.lifetime',
          'storeId': '9LIFE',
          'price': r'$29.99',
          'fullPrice': r'$39.99',
        },
        {
          'token': 'restifeye.yearly',
          'storeId': '9YEAR',
          'price': r'$11.99',
          'fullPrice': '',
        },
      ],
    };
    final offers = await store().offers();
    expect(offers.map((o) => o.plan), [Plan.yearly, Plan.lifetime]);
    expect(offers.first.fullPrice, isNull);
    expect(offers.last.price, r'$29.99');
    expect(offers.last.fullPrice, r'$39.99');
  });

  test('buying looks up the Store ID and maps the outcome', () async {
    replies['storeOffers'] = {
      'ok': true,
      'error': '',
      'offers': [
        {'token': 'restifeye.yearly', 'storeId': '9YEAR', 'price': r'$11.99'},
      ],
    };
    replies['storePurchase'] = {'status': 'cancelled', 'error': ''};
    expect(await store().buy(Plan.yearly), PurchaseOutcome.cancelled);
    final purchase = calls.firstWhere((c) => c.method == 'storePurchase');
    expect((purchase.arguments as Map)['storeId'], '9YEAR');

    expect(await store().buy(Plan.lifetime), PurchaseOutcome.failed);
  });

  test('the startup task counts as on only when Windows says so', () {
    expect(startupTaskOn('enabled'), isTrue);
    expect(startupTaskOn('enabledByPolicy'), isTrue);
    expect(startupTaskOn('disabledByUser'), isFalse);
    expect(startupTaskOn('error'), isFalse);
  });
}
