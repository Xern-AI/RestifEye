/// The two tiers of breaks.
enum BreakKind {
  /// Short eye break (20-20-20 rule).
  micro,

  /// Longer movement break.
  long,
}

/// How a scheduled break concluded, for compliance analytics.
enum BreakOutcome { completed, escaped, creditedIdle, creditedLock }
