// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/mood/mood_window.dart';

void main() {
  final now = DateTime(2026, 7, 22, 21, 30);
  DateTime ago(Duration d) => now.subtract(d);

  group('MoodWindow', () {
    test('keeps only the most recent responses', () {
      final window = MoodWindow(size: 3);
      for (var i = 6; i >= 1; i--) {
        window.record(BreakResponse.skipped, ago(Duration(minutes: i)));
      }
      window.record(BreakResponse.honored, now);

      expect(window.responsesAt(now), hasLength(3));
      expect(window.responsesAt(now).last, BreakResponse.honored);
    });

    // The bug this class exists for: breaks escaped before lunch were still
    // colouring the icon at midnight, so a break taken right now changed
    // nothing the user could see.
    test('forgets responses older than the horizon', () {
      final window = MoodWindow(horizon: const Duration(hours: 2))
        ..record(BreakResponse.escaped, ago(const Duration(hours: 9)))
        ..record(BreakResponse.escaped, ago(const Duration(hours: 9)))
        ..record(BreakResponse.honored, ago(const Duration(minutes: 5)));

      expect(window.responsesAt(now), [BreakResponse.honored]);
    });

    test('a response exactly at the horizon has expired', () {
      final window = MoodWindow(horizon: const Duration(hours: 2))
        ..record(BreakResponse.skipped, ago(const Duration(hours: 2)));

      expect(window.responsesAt(now), isEmpty);
    });

    test('expiry is a function of the moment it is asked about', () {
      final window = MoodWindow(horizon: const Duration(hours: 2))
        ..record(BreakResponse.skipped, ago(const Duration(minutes: 30)));

      expect(window.responsesAt(now), hasLength(1));
      expect(
        window.responsesAt(now.add(const Duration(hours: 2))),
        isEmpty,
        reason: 'nothing has to happen for a mood to lapse but time',
      );
    });
  });

  group('persistence', () {
    test('round-trips through storage', () {
      final saved = MoodWindow()
        ..record(BreakResponse.honored, ago(const Duration(minutes: 40)))
        ..record(BreakResponse.snoozed, ago(const Duration(minutes: 20)));

      final restored = MoodWindow.decode(saved.encode(), now: now);

      expect(restored.responsesAt(now), [
        BreakResponse.honored,
        BreakResponse.snoozed,
      ]);
    });

    // Restarting must not be a way to clear a warning...
    test('a recent warning survives a restart', () {
      final saved = MoodWindow()
        ..record(BreakResponse.skipped, ago(const Duration(minutes: 10)))
        ..record(BreakResponse.skipped, ago(const Duration(minutes: 5)));

      expect(MoodWindow.decode(saved.encode(), now: now).responsesAt(now), [
        BreakResponse.skipped,
        BreakResponse.skipped,
      ]);
    });

    // ...but coming back after lunch legitimately starts clean.
    test('a stale session does not colour the next one', () {
      final saved = MoodWindow()
        ..record(BreakResponse.skipped, ago(const Duration(hours: 9)))
        ..record(BreakResponse.escaped, ago(const Duration(hours: 8)));

      expect(
        MoodWindow.decode(saved.encode(), now: now).responsesAt(now),
        isEmpty,
      );
    });

    test('entries from the untimestamped format are discarded', () {
      // They carry no evidence of when they happened, and trusting them is
      // precisely what made the icon lie.
      expect(
        MoodWindow.decode('honored,escaped,escaped', now: now).responsesAt(now),
        isEmpty,
      );
    });

    test('nothing stored means no opinion', () {
      expect(MoodWindow.decode(null, now: now).responsesAt(now), isEmpty);
      expect(MoodWindow.decode('', now: now).responsesAt(now), isEmpty);
    });

    test('a corrupt entry is skipped, not fatal', () {
      final raw = 'honored@${now.millisecondsSinceEpoch ~/ 1000},nonsense@x,@,';

      expect(MoodWindow.decode(raw, now: now).responsesAt(now), [
        BreakResponse.honored,
      ]);
    });
  });
}
