// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Crash-safe persistence of engine timers. Wall-clock based so it survives
/// process restarts (the monotonic clock does not).
class EngineSnapshot {
  const EngineSnapshot({
    required this.savedAt,
    required this.microRemaining,
    required this.longRemaining,
  });

  final DateTime savedAt;
  final Duration microRemaining;
  final Duration longRemaining;

  Map<String, Object> toJson() => {
    'savedAt': savedAt.toIso8601String(),
    'microRemainingMs': microRemaining.inMilliseconds,
    'longRemainingMs': longRemaining.inMilliseconds,
  };

  static EngineSnapshot? fromJson(Map<String, Object?> json) {
    final savedAt = DateTime.tryParse(json['savedAt'] as String? ?? '');
    final micro = json['microRemainingMs'];
    final long = json['longRemainingMs'];
    if (savedAt == null || micro is! int || long is! int) return null;
    return EngineSnapshot(
      savedAt: savedAt,
      microRemaining: Duration(milliseconds: micro),
      longRemaining: Duration(milliseconds: long),
    );
  }
}
