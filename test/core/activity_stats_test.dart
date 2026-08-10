// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:restifeye/core/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 7, 14, 9);
  DateTime at(int minutes) => day.add(Duration(minutes: minutes));

  ActivitySlice slice(int fromMinute, int toMinute, SliceKind kind) =>
      ActivitySlice(start: at(fromMinute), end: at(toMinute), kind: kind);

  /// What the writer actually produces: EngineService flushes the recorder
  /// once a minute for crash-safety, so a continuous run reaches the database
  /// as a chain of one-minute slices that adjoin exactly.
  List<ActivitySlice> minuteChopped(int from, int to, SliceKind kind) => [
    for (var m = from; m < to; m++) slice(m, m + 1, kind),
  ];

  group('longest stretch', () {
    test('merges the one-minute slices a crash-safety flush leaves behind', () {
      // 90 unbroken minutes of work, stored as 90 slices.
      final stats = computeSliceStats(minuteChopped(0, 90, SliceKind.active));

      expect(
        stats.longestStretch,
        const Duration(minutes: 90),
        reason: 'reading the longest single slice reported 1m forever',
      );
      expect(stats.screenTime, const Duration(minutes: 90));
    });

    test('a gap in activity ends the stretch', () {
      final stats = computeSliceStats([
        ...minuteChopped(0, 30, SliceKind.active),
        ...minuteChopped(30, 35, SliceKind.idle),
        ...minuteChopped(35, 80, SliceKind.active), // the longer run
        ...minuteChopped(80, 90, SliceKind.locked),
        ...minuteChopped(90, 100, SliceKind.active),
      ]);

      expect(stats.longestStretch, const Duration(minutes: 45));
      expect(stats.screenTime, const Duration(minutes: 85));
      expect(stats.idleTime, const Duration(minutes: 5));
      expect(stats.awayTime, const Duration(minutes: 10));
    });

    test('order does not matter', () {
      final chopped = minuteChopped(0, 40, SliceKind.active)..shuffle();
      expect(
        computeSliceStats(chopped).longestStretch,
        const Duration(minutes: 40),
      );
    });

    test('a non-adjoining active slice starts a new stretch', () {
      // A hole with no slice at all (app was down) is not one stretch.
      final stats = computeSliceStats([
        slice(0, 20, SliceKind.active),
        slice(40, 70, SliceKind.active),
      ]);
      expect(stats.longestStretch, const Duration(minutes: 30));
    });

    test('no activity yields zero, not a crash', () {
      final stats = computeSliceStats(const []);
      expect(stats.longestStretch, Duration.zero);
      expect(stats.firstActivity, isNull);
      expect(stats.workdaySpan, isNull);
    });
  });

  test('workday span runs from first to last activity', () {
    final stats = computeSliceStats([
      ...minuteChopped(0, 10, SliceKind.active),
      ...minuteChopped(10, 300, SliceKind.idle),
      ...minuteChopped(300, 310, SliceKind.active),
    ]);
    expect(stats.firstActivity, at(0));
    expect(stats.lastActivity, at(310));
    expect(stats.workdaySpan, const Duration(minutes: 310));
    expect(stats.atComputer, const Duration(minutes: 310));
  });
}
