// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// How the app feels about how the user's day is going, expressed through
/// the tray icon's face.
///
/// Two of these are *transient* states of the moment rather than judgements
/// of behaviour ([Mood.paused], [Mood.resting]); the rest sit on a severity
/// scale that drives the hysteresis in `MoodTracker`.
enum Mood {
  /// Breaks are off. Neutral — the app has no opinion while it is not
  /// working.
  paused,

  /// A break is happening right now. Eyes closed, at peace.
  resting,

  /// Following breaks consistently.
  great,

  /// Nothing to report. The everyday resting state.
  good,

  /// A long stretch at the screen without enough rest behind it.
  tired,

  /// Breaks are starting to be pushed away.
  slipping,

  /// Breaks are being skipped repeatedly.
  ignoring;

  /// Whether this mood describes the current moment rather than a pattern of
  /// behaviour. Transient moods bypass hysteresis: they must appear and clear
  /// instantly, and they must not overwrite the behavioural mood underneath.
  bool get isTransient => this == Mood.paused || this == Mood.resting;

  /// Ordering used to decide whether a change is an escalation (slower, to
  /// avoid nagging on one bad break) or a de-escalation (immediate, because
  /// good behaviour should be acknowledged at once).
  ///
  /// Transient moods are not on the scale and must never be compared.
  int get severity => switch (this) {
    Mood.great => 0,
    Mood.good => 1,
    Mood.tired => 2,
    Mood.slipping => 3,
    Mood.ignoring => 4,
    Mood.paused || Mood.resting => -1,
  };
}
