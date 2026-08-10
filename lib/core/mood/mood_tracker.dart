// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'mood.dart';

/// Smooths the raw mood so the tray icon does not flicker.
///
/// Without this the icon changes on almost every tick as one break rolls out
/// of the window and another rolls in — which reads as noise, and noise in
/// the corner of the eye is exactly what this app exists not to be.
///
/// The asymmetry is the point: **praise quickly, scold slowly.** Improving
/// is adopted the moment it happens, so doing the right thing is
/// acknowledged immediately. Getting worse has to persist across
/// [escalateAfter] samples, so a single skipped break — which everyone does,
/// for good reasons — never turns the icon red on its own.
class MoodTracker {
  MoodTracker({this.escalateAfter = 3, Mood initial = Mood.good})
    : _steady = initial;

  /// Consecutive worse-than-current samples required before escalating.
  final int escalateAfter;

  /// The last settled behavioural mood. Transient moods never touch this, so
  /// a break or a pause cannot erase what the app had concluded about the
  /// day — it is still there when the break ends.
  Mood _steady;

  Mood? _pending;
  int _pendingCount = 0;

  Mood get current => _steady;

  /// Adopts [mood] as the settled state, skipping hysteresis.
  ///
  /// Hysteresis smooths *transitions*, and a first reading is not one. Left
  /// to escalate into its own restored history the tracker would start every
  /// launch cheerful and then turn red a few minutes later with nothing
  /// having happened — a colour change the user cannot connect to anything
  /// they did, which is worse than the warning arriving honestly at startup.
  void settle(Mood mood) {
    if (mood.isTransient) return; // a moment is not a settled state
    _steady = mood;
    _pending = null;
    _pendingCount = 0;
  }

  /// Feeds one sample and returns the mood to display.
  Mood update(Mood raw) {
    // "In a break" and "paused" describe the moment, not the pattern. They
    // show through immediately and are not subject to hysteresis, because
    // the icon lagging three ticks behind the break the user is looking at
    // would just be wrong.
    //
    // A half-finished escalation does not survive one, either: the samples
    // on the far side of a break describe a different situation, and the
    // break itself is usually what changed it.
    if (raw.isTransient) {
      _pending = null;
      _pendingCount = 0;
      return raw;
    }

    if (raw == _steady) {
      _pending = null;
      _pendingCount = 0;
      return _steady;
    }

    if (raw.severity < _steady.severity) {
      _steady = raw; // improving: adopt at once
      _pending = null;
      _pendingCount = 0;
      return _steady;
    }

    // Worsening: require persistence. A different worse mood restarts the
    // count rather than inheriting the previous candidate's progress.
    if (raw != _pending) {
      _pending = raw;
      _pendingCount = 1;
    } else {
      _pendingCount++;
    }
    if (_pendingCount >= escalateAfter) {
      _steady = raw;
      _pending = null;
      _pendingCount = 0;
    }
    return _steady;
  }
}
