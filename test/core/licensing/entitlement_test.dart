// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/licensing/entitlement.dart';

void main() {
  final start = DateTime(2026, 10, 25, 9);

  Entitlement at(
    Duration after, {
    Set<Plan> owned = const {},
    bool store = true,
  }) => entitlementFrom(
    storeBuild: store,
    trialStartedAt: start,
    now: start.add(after),
    owned: owned,
  );

  test('Linux and the test zips are never licensed', () {
    expect(at(const Duration(days: 400), store: false), const Unlimited());
  });

  test('the trial counts down 14 whole days, then ends', () {
    expect(at(Duration.zero), const Trial(14));
    expect(at(const Duration(hours: 1)), const Trial(14));
    expect(at(const Duration(days: 1)), const Trial(13));
    expect(at(const Duration(days: 13, hours: 23)), const Trial(1));
    expect(at(const Duration(days: 14)), const TrialEnded());
    expect(at(const Duration(days: 30)), const TrialEnded());
  });

  test('a plan unlocks at once, mid-trial or after it; Lifetime wins', () {
    expect(
      at(const Duration(days: 3), owned: {Plan.yearly}),
      const Owned(Plan.yearly),
    );
    expect(
      at(const Duration(days: 90), owned: {Plan.lifetime}),
      const Owned(Plan.lifetime),
    );
    expect(
      at(const Duration(days: 90), owned: {Plan.yearly, Plan.lifetime}),
      const Owned(Plan.lifetime),
    );
  });

  test('only an ended trial stops reminders', () {
    expect(const Trial(1).remindersAllowed, isTrue);
    expect(const Owned(Plan.yearly).remindersAllowed, isTrue);
    expect(const Unlimited().remindersAllowed, isTrue);
    expect(const TrialEnded().remindersAllowed, isFalse);
  });
}
