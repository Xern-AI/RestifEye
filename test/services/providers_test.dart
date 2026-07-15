import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/clock.dart';
import 'package:restifeye/services/providers.dart';

void main() {
  group('todayProvider', () {
    test('rolls over to the new day shortly after midnight', () {
      fakeAsync((async) {
        final clock = ManualClock(startAt: DateTime(2026, 7, 14, 23, 59));
        final container = ProviderContainer(
          overrides: [wallClockProvider.overrideWithValue(clock.now)],
        );

        expect(container.read(todayProvider), DateTime(2026, 7, 14));

        // Same day: the periodic check must not churn the value.
        clock.advance(const Duration(seconds: 30));
        async.elapse(const Duration(seconds: 30));
        expect(container.read(todayProvider), DateTime(2026, 7, 14));

        // Cross midnight: the next check rolls the day over.
        clock.advance(const Duration(minutes: 2));
        async.elapse(const Duration(seconds: 30));
        expect(container.read(todayProvider), DateTime(2026, 7, 15));

        container.dispose();
        expect(async.periodicTimerCount, 0);
      });
    });

    test('survives suspend: a late periodic tick still catches up', () {
      fakeAsync((async) {
        final clock = ManualClock(startAt: DateTime(2026, 7, 14, 22));
        final container = ProviderContainer(
          overrides: [wallClockProvider.overrideWithValue(clock.now)],
        );

        expect(container.read(todayProvider), DateTime(2026, 7, 14));

        // The machine sleeps for ten hours; the wall clock leaps while the
        // timer only fires once resumed. One tick must be enough.
        clock.advance(const Duration(hours: 10));
        async.elapse(const Duration(seconds: 30));
        expect(container.read(todayProvider), DateTime(2026, 7, 15));

        container.dispose();
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
