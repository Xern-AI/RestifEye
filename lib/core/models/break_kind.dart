// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// The two tiers of breaks.
enum BreakKind {
  /// Short eye break (20-20-20 rule).
  micro,

  /// Longer movement break.
  long,
}

/// How a scheduled break concluded, for compliance analytics.
enum BreakOutcome { completed, escaped, creditedIdle, creditedLock }
