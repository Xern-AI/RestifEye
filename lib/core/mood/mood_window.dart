// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// What happened to a break the user was offered.
enum BreakResponse { honored, snoozed, skipped, escaped }

/// One response, and when it happened.
///
/// The timestamp is the whole point. Without it a response is evidence
/// forever: skipping two breaks before lunch still coloured the icon at
/// midnight, and survived a restart to colour it the next morning too.
class MoodSample {
  const MoodSample(this.response, this.at);

  final BreakResponse response;
  final DateTime at;
}

/// The evidence the mood is judged on: the last few break responses, none of
/// them older than [horizon].
///
/// Bounded twice, because either bound alone is wrong. By count only, a quiet
/// evening after a bad morning shows the morning — the user cannot earn the
/// icon back except by taking more breaks than the app will offer. By time
/// only, a burst of breaks in one busy hour outvotes everything. Together
/// they answer the question the icon is actually asking: *how is it going
/// right now?*
class MoodWindow {
  MoodWindow({
    this.size = defaultSize,
    this.horizon = defaultHorizon,
    List<MoodSample> samples = const [],
  }) : _samples = [...samples];

  /// How many responses are kept.
  static const defaultSize = 5;

  /// How long a response stays relevant.
  ///
  /// Two hours is roughly four long-break cycles: long enough that a pattern
  /// needs more than one bad break to form, short enough that the icon is
  /// always describing the session the user is actually in. It is also what
  /// makes a restart honest — the window is still persisted, so restarting is
  /// not a way to clear a warning, but coming back after lunch legitimately
  /// starts clean.
  static const defaultHorizon = Duration(hours: 2);

  final int size;
  final Duration horizon;

  final List<MoodSample> _samples;

  /// The responses still worth judging on, oldest first.
  List<BreakResponse> responsesAt(DateTime now) {
    final cutoff = now.subtract(horizon);
    return [
      for (final s in _samples)
        if (s.at.isAfter(cutoff)) s.response,
    ];
  }

  void record(BreakResponse response, DateTime at) {
    _samples.add(MoodSample(response, at));
    // Only the window is ever consulted, so only the window is kept — this
    // list must not grow for the lifetime of the process.
    while (_samples.length > size) {
      _samples.removeAt(0);
    }
  }

  /// `response@epochSeconds`, comma separated.
  String encode() => _samples
      .map((s) => '${s.response.name}@${s.at.millisecondsSinceEpoch ~/ 1000}')
      .join(',');

  /// Rebuilds a window from [raw], dropping anything already expired at
  /// [now].
  ///
  /// Entries without a timestamp are from the format that caused the bug —
  /// they carry no evidence of when they happened, so they are dropped
  /// rather than trusted.
  static MoodWindow decode(
    String? raw, {
    required DateTime now,
    int size = defaultSize,
    Duration horizon = defaultHorizon,
  }) {
    final window = MoodWindow(size: size, horizon: horizon);
    if (raw == null || raw.isEmpty) return window;

    final byName = {for (final r in BreakResponse.values) r.name: r};
    final cutoff = now.subtract(horizon);
    for (final entry in raw.split(',')) {
      final parts = entry.split('@');
      if (parts.length != 2) continue;
      final response = byName[parts[0]];
      final seconds = int.tryParse(parts[1]);
      if (response == null || seconds == null) continue;
      final at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      if (!at.isAfter(cutoff)) continue;
      window.record(response, at);
    }
    return window;
  }
}
