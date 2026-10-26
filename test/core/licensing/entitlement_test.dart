// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/licensing/entitlement.dart';

void main() {
  final now = DateTime(2026, 10, 25, 9);

  StoreLicence trialEnding(Duration after, {bool active = true}) =>
      StoreLicence(
        fromStore: true,
        active: active,
        trial: true,
        trialEndsAt: now.add(after),
      );

  Entitlement at(StoreLicence? licence, {bool store = true}) =>
      entitlementFrom(storeBuild: store, licence: licence, now: now);

  test('Linux, test zips and sideloaded packages are never licensed', () {
    expect(at(trialEnding(Duration.zero), store: false), const Unlimited());
    expect(
      at(const StoreLicence(fromStore: false, active: false, trial: false)),
      const Unlimited(),
    );
  });

  test('a Store that never answered locks nothing', () {
    expect(at(null), const Unlimited());
  });

  test('the Store trial counts down whole days to its end date', () {
    expect(at(trialEnding(const Duration(days: 15))), const Trial(15));
    expect(
      at(trialEnding(const Duration(days: 14, hours: 1))),
      const Trial(15),
    );
    expect(at(trialEnding(const Duration(hours: 3))), const Trial(1));
    expect(at(trialEnding(Duration.zero)), const TrialEnded());
    expect(at(trialEnding(const Duration(days: -2))), const TrialEnded());
  });

  test('a trial the Store reports inactive has ended', () {
    expect(
      at(trialEnding(const Duration(days: 3), active: false)),
      const TrialEnded(),
    );
  });

  test('a full licence is owned; an inactive one is not', () {
    expect(
      at(const StoreLicence(fromStore: true, active: true, trial: false)),
      const Owned(),
    );
    expect(
      at(const StoreLicence(fromStore: true, active: false, trial: false)),
      const TrialEnded(),
    );
  });

  test('only an ended trial stops reminders', () {
    expect(const Trial(1).remindersAllowed, isTrue);
    expect(const Owned().remindersAllowed, isTrue);
    expect(const Unlimited().remindersAllowed, isTrue);
    expect(const TrialEnded().remindersAllowed, isFalse);
  });
}
