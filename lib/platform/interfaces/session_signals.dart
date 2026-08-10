// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Session lock/suspend state.
abstract interface class SessionSignals {
  /// Emits `true` when the session locks or the system suspends,
  /// `false` when it unlocks/resumes. May emit duplicates.
  Stream<bool> get away;

  Future<void> dispose();
}
