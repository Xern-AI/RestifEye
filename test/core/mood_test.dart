import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/mood/mood.dart';
import 'package:restifeye/core/mood/mood_rules.dart';
import 'package:restifeye/core/mood/mood_tracker.dart';

void main() {
  group('computeMood', () {
    const honored = BreakResponse.honored;
    const skipped = BreakResponse.skipped;
    const snoozed = BreakResponse.snoozed;

    test('a paused engine has no opinion', () {
      expect(
        computeMood(
          const MoodInputs(recent: [skipped, skipped, skipped], paused: true),
        ),
        Mood.paused,
      );
    });

    test('a break in progress shows rest, whatever the history', () {
      expect(
        computeMood(
          const MoodInputs(recent: [skipped, skipped, skipped], inBreak: true),
        ),
        Mood.resting,
      );
    });

    test('no history withholds judgement', () {
      expect(computeMood(const MoodInputs()), Mood.good);
    });

    test('taking breaks earns praise', () {
      expect(
        computeMood(
          const MoodInputs(recent: [honored, honored, honored, honored]),
        ),
        Mood.great,
      );
    });

    test('a couple of skips reads as slipping', () {
      expect(
        computeMood(const MoodInputs(recent: [honored, skipped, skipped])),
        Mood.slipping,
      );
    });

    test('persistent skipping reads as ignoring', () {
      expect(
        computeMood(const MoodInputs(recent: [skipped, skipped, skipped])),
        Mood.ignoring,
      );
    });

    // A snooze is a deferral the app itself offers. Treating one like a skip
    // would punish users for using a feature as intended.
    test('one snooze is not held against the user', () {
      expect(
        computeMood(
          const MoodInputs(recent: [honored, honored, honored, snoozed]),
        ),
        Mood.good,
      );
    });

    test('but habitual snoozing counts as slipping', () {
      expect(
        computeMood(const MoodInputs(recent: [snoozed, snoozed, snoozed])),
        Mood.slipping,
      );
    });

    test('a long stretch without rest reads as tired', () {
      expect(
        computeMood(
          const MoodInputs(
            recent: [honored, honored],
            sinceLastRest: Duration(hours: 2),
          ),
        ),
        Mood.tired,
      );
    });

    test('a long day reads as tired even when fully compliant', () {
      expect(
        computeMood(
          const MoodInputs(
            recent: [honored, honored, honored, honored],
            screenTime: Duration(hours: 7),
          ),
        ),
        Mood.tired,
      );
    });

    // Being told breaks are being skipped is more actionable than being told
    // the day is long, so it must not be masked by fatigue.
    test('skipping outranks tiredness', () {
      expect(
        computeMood(
          const MoodInputs(
            recent: [skipped, skipped, skipped],
            screenTime: Duration(hours: 9),
            sinceLastRest: Duration(hours: 3),
          ),
        ),
        Mood.ignoring,
      );
    });

    test('only the most recent responses count', () {
      // Three old skips have rolled out of a five-wide window.
      expect(
        computeMood(
          const MoodInputs(
            recent: [
              skipped,
              skipped,
              skipped,
              honored,
              honored,
              honored,
              honored,
              honored,
            ],
          ),
        ),
        Mood.great,
        reason: 'a bad morning must not colour the icon all day',
      );
    });
  });

  group('MoodTracker hysteresis', () {
    test('improvement is adopted immediately', () {
      final tracker = MoodTracker(initial: Mood.ignoring);
      expect(tracker.update(Mood.great), Mood.great);
    });

    test('worsening requires persistence', () {
      final tracker = MoodTracker(escalateAfter: 3);
      expect(tracker.update(Mood.ignoring), Mood.good);
      expect(tracker.update(Mood.ignoring), Mood.good);
      expect(
        tracker.update(Mood.ignoring),
        Mood.ignoring,
        reason: 'only after the third consecutive sample',
      );
    });

    test('a single bad sample never escalates', () {
      final tracker = MoodTracker(escalateAfter: 3);
      tracker.update(Mood.slipping);
      expect(tracker.update(Mood.good), Mood.good);
      tracker.update(Mood.slipping);
      expect(
        tracker.current,
        Mood.good,
        reason: 'the pending count resets when the mood recovers',
      );
    });

    test('a different worse mood restarts the count', () {
      final tracker = MoodTracker(escalateAfter: 3);
      tracker.update(Mood.slipping);
      tracker.update(Mood.slipping);
      tracker.update(Mood.ignoring); // restarts at 1
      expect(tracker.current, Mood.good);
      tracker.update(Mood.ignoring);
      expect(tracker.update(Mood.ignoring), Mood.ignoring);
    });

    // Launching cheerful and turning red three minutes later, with nothing
    // having happened in between, is a colour change the user cannot connect
    // to anything they did.
    test('a restored mood is adopted at once, not escalated into', () {
      final tracker = MoodTracker(escalateAfter: 3)..settle(Mood.slipping);

      expect(tracker.current, Mood.slipping);
      expect(tracker.update(Mood.slipping), Mood.slipping);
    });

    test('settling ignores a transient mood', () {
      final tracker = MoodTracker(initial: Mood.tired)..settle(Mood.resting);

      expect(
        tracker.current,
        Mood.tired,
        reason: 'a moment is not a settled state',
      );
    });

    test('a half-finished escalation does not survive a break', () {
      final tracker = MoodTracker(escalateAfter: 3);
      tracker.update(Mood.slipping);
      tracker.update(Mood.slipping);

      tracker.update(Mood.resting); // the user takes the break

      expect(tracker.update(Mood.slipping), Mood.good);
      expect(
        tracker.update(Mood.slipping),
        Mood.good,
        reason: 'the count restarts on the far side of the break',
      );
    });

    test('transient moods pass through without disturbing the steady one', () {
      final tracker = MoodTracker(initial: Mood.slipping);
      expect(tracker.update(Mood.resting), Mood.resting);
      expect(tracker.update(Mood.paused), Mood.paused);
      expect(
        tracker.current,
        Mood.slipping,
        reason: 'a break must not erase what the day established',
      );
    });
  });
}
