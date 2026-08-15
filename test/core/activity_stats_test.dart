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

  group('classifying a second', () {
    const threshold = Duration(minutes: 2);
    SliceKind classify({
      bool away = false,
      Duration idle = Duration.zero,
      bool presenting = false,
    }) => classifySlice(
      away: away,
      idle: idle,
      idleThreshold: threshold,
      presenting: presenting,
    );

    test('away outranks everything, including a playing film', () {
      expect(
        classify(away: true, presenting: true, idle: const Duration(hours: 1)),
        SliceKind.locked,
      );
    });

    // Otherwise a background video would swallow a morning of real work.
    test('typing during a video is work, not watching', () {
      expect(classify(presenting: true), SliceKind.active);
    });

    test('hands off with something playing is watching', () {
      expect(
        classify(idle: const Duration(minutes: 5), presenting: true),
        SliceKind.watching,
      );
    });

    test('hands off with nothing playing is plain idle', () {
      expect(classify(idle: const Duration(minutes: 5)), SliceKind.idle);
    });
  });

  group('watching', () {
    test('is counted apart from idle but still counts as at the computer', () {
      final stats = computeSliceStats([
        ...minuteChopped(0, 30, SliceKind.active),
        ...minuteChopped(30, 90, SliceKind.watching),
        ...minuteChopped(90, 100, SliceKind.idle),
      ]);

      expect(stats.watchTime, const Duration(minutes: 60));
      expect(stats.idleTime, const Duration(minutes: 10));
      expect(stats.atComputer, const Duration(minutes: 100));
      // An hour of film is not an hour of work.
      expect(stats.screenTime, const Duration(minutes: 30));
    });

    test('ends a focus stretch, exactly as idling does', () {
      final stats = computeSliceStats([
        ...minuteChopped(0, 40, SliceKind.active),
        ...minuteChopped(40, 45, SliceKind.watching),
        ...minuteChopped(45, 70, SliceKind.active),
      ]);
      expect(stats.longestStretch, const Duration(minutes: 40));
    });
  });

  group('deep-work runs', () {
    test('counts every run that reaches the threshold, not just the best', () {
      final stats = computeSliceStats([
        ...minuteChopped(0, 30, SliceKind.active),
        ...minuteChopped(30, 40, SliceKind.idle),
        ...minuteChopped(40, 80, SliceKind.active),
        ...minuteChopped(80, 90, SliceKind.idle),
        ...minuteChopped(90, 100, SliceKind.active), // too short to count
      ]);
      expect(stats.focusRuns, 2);
      expect(stats.longestStretch, const Duration(minutes: 40));
    });

    test('a run one minute short of the threshold does not count', () {
      final stats = computeSliceStats(
        minuteChopped(0, focusRunMinimum.inMinutes - 1, SliceKind.active),
      );
      expect(stats.focusRuns, 0);
    });
  });

  group('hourly profile', () {
    test('charges a slice to every hour it actually occupies', () {
      // 09:00 start; 100 minutes runs into the 10th and 11th hours.
      final stats = computeSliceStats([slice(0, 100, SliceKind.active)]);

      expect(stats.hours, hasLength(24));
      expect(stats.hours[9].active, 60 * 60);
      expect(stats.hours[10].active, 40 * 60);
      expect(stats.hours[11].active, 0);
    });

    test('peak hour is the busiest hands-on hour', () {
      final stats = computeSliceStats([
        slice(0, 20, SliceKind.active), // 09:00
        slice(120, 170, SliceKind.active), // 11:00
        slice(180, 240, SliceKind.watching), // 12:00, not hands-on
      ]);
      expect(stats.peakHour, 11);
    });

    test('peak hour is null when nothing was recorded', () {
      expect(computeSliceStats(const []).peakHour, isNull);
    });

    test('late and early work is counted outside 07:00-22:00', () {
      final night = DateTime(2026, 7, 14, 23);
      final stats = computeSliceStats([
        ActivitySlice(
          start: night,
          end: night.add(const Duration(minutes: 45)),
          kind: SliceKind.active,
        ),
      ]);
      expect(stats.afterHours, const Duration(minutes: 45));
    });

    test('a normal working hour is not counted as late', () {
      final stats = computeSliceStats([slice(0, 45, SliceKind.active)]);
      expect(stats.afterHours, Duration.zero);
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
