// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/engine/events.dart';
import 'package:restifeye/core/engine/phase.dart';

import 'engine_test.dart' show Rig;

void main() {
  test('a locked-out engine issues no warnings and says why', () {
    final rig = Rig()..engine.setLockedOut(true);
    rig.run(const Duration(hours: 2));

    expect(rig.eventsOf<WarningIssued>(), isEmpty);
    expect(
      rig.engine.phase,
      isA<Paused>().having((p) => p.reason, 'reason', PauseReason.trialEnded),
    );
  });

  test('the lockout outranks the user pause and survives its toggle', () {
    final rig = Rig()..engine.setLockedOut(true);
    rig.engine
      ..setPausedByUser(true)
      ..setPausedByUser(false);
    rig.run(const Duration(minutes: 30));

    expect(rig.eventsOf<WarningIssued>(), isEmpty);
    expect((rig.engine.phase as Paused).reason, PauseReason.trialEnded);
  });

  test('a lockout during a break ends the break; lifting it starts fresh', () {
    final rig = Rig();
    rig.run(const Duration(minutes: 20, seconds: 5));
    expect(rig.engine.phase, isA<InBreak>());

    rig.engine.setLockedOut(true);
    expect((rig.engine.phase as Paused).reason, PauseReason.trialEnded);

    rig.engine.setLockedOut(false);
    expect(rig.eventsOf<EngineResumed>(), hasLength(1));
    rig.run(const Duration(minutes: 19));
    expect(rig.engine.phase, isA<Monitoring>());
    rig.run(const Duration(minutes: 1));
    expect(rig.eventsOf<WarningIssued>(), hasLength(2));
  });

  test('setting the same lockout twice changes nothing', () {
    final rig = Rig()..engine.setLockedOut(false);
    expect(rig.eventsOf<EngineResumed>(), isEmpty);
  });
}
