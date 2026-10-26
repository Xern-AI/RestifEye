// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// A paid plan on the Microsoft Store build.
enum Plan { yearly, lifetime }

/// What this copy of the app may do.
sealed class Entitlement {
  const Entitlement();

  /// Whether break reminders may run.
  bool get remindersAllowed => this is! TrialEnded;
}

/// No licensing applies: Linux, and the Windows test zips.
class Unlimited extends Entitlement {
  const Unlimited();
}

/// The free trial is running.
class Trial extends Entitlement {
  const Trial(this.daysLeft);

  /// Whole days left, counting today; 1 on the last day.
  final int daysLeft;

  @override
  bool operator ==(Object other) =>
      other is Trial && other.daysLeft == daysLeft;

  @override
  int get hashCode => daysLeft.hashCode;
}

/// A plan is owned.
class Owned extends Entitlement {
  const Owned(this.plan);

  final Plan plan;

  @override
  bool operator ==(Object other) => other is Owned && other.plan == plan;

  @override
  int get hashCode => plan.hashCode;
}

/// The trial is over and no plan is owned: reminders stop, history stays.
class TrialEnded extends Entitlement {
  const TrialEnded();
}

/// Free trial length on the Store build (founder, 23 Oct 2026).
const trialLength = Duration(days: 14);

/// The one rule every licensing decision comes from.
///
/// A plan always wins, so a purchase unlocks at once even mid-trial; Lifetime
/// wins over Yearly. The trial counts down in whole days from when it began,
/// on the wall clock, so it survives restarts and sleep.
Entitlement entitlementFrom({
  required bool storeBuild,
  required DateTime trialStartedAt,
  required DateTime now,
  required Set<Plan> owned,
}) {
  if (!storeBuild) return const Unlimited();
  if (owned.contains(Plan.lifetime)) return const Owned(Plan.lifetime);
  if (owned.contains(Plan.yearly)) return const Owned(Plan.yearly);
  final left = trialStartedAt.add(trialLength).difference(now);
  if (left <= Duration.zero) return const TrialEnded();
  return Trial((left.inMinutes / Duration.minutesPerDay).ceil());
}
