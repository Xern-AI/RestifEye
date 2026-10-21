// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/engine/phase.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/services/phase_log.dart';

void main() {
  test('labels carry what matters for a log, never the countdown', () {
    expect(
      phaseLabel(
        const Monitoring(
          nextBreakIn: Duration(minutes: 3),
          nextBreakKind: BreakKind.micro,
          microIn: Duration(minutes: 3),
          longIn: Duration(minutes: 40),
        ),
      ),
      'monitoring (next micro)',
    );
    expect(
      phaseLabel(
        const Warning(kind: BreakKind.long, startsIn: Duration(seconds: 29)),
      ),
      phaseLabel(
        const Warning(kind: BreakKind.long, startsIn: Duration(seconds: 3)),
      ),
    );
    expect(
      phaseLabel(
        const InBreak(
          kind: BreakKind.micro,
          remaining: Duration(seconds: 12),
          snoozesLeft: 0,
          strict: true,
          held: true,
        ),
      ),
      'break micro strict held',
    );
    expect(
      phaseLabel(
        const Deferred(kind: BreakKind.long, recheckIn: Duration(seconds: 5)),
      ),
      'deferred long (busy)',
    );
    expect(
      phaseLabel(const Paused(reason: PauseReason.media, byApp: 'vlc.exe')),
      'paused media by vlc.exe',
    );
  });
}
