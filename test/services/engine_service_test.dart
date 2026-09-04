// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart' hide EnginePhase;
import 'package:restifeye/core/engine/phase.dart';

import '../helpers/overrides.dart';

/// Proves the wiring, not the policy: the service asks the window whether it
/// still has the user, and the engine acts on the answer. Everything about
/// *how* a hold behaves is covered in the engine's own tests.
void main() {
  test('a break the user has switched away from does not tick down', () {
    fakeAsync((async) {
      final harness = TestHarness();
      harness.advance(const Duration(minutes: 19, seconds: 40));
      harness.engine.startNow();
      expect(harness.engine.phase, isA<InBreak>());

      harness.overlay.focused = false;
      harness.service.start();
      // The real clock the engine reads is manual, so it has to be advanced
      // alongside the timer that drives the ticks.
      for (var i = 0; i < 30; i++) {
        harness.clock.advance(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
      }

      final phase = harness.engine.phase;
      expect(phase, isA<InBreak>(), reason: 'the break must still be owed');
      expect((phase as InBreak).held, isTrue);
      expect(phase.remaining, const Duration(seconds: 20));
    });
  });
}
