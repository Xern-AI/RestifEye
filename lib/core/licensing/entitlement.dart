// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// The app's own licence as the Microsoft Store reports it.
class StoreLicence {
  const StoreLicence({
    required this.fromStore,
    required this.active,
    required this.trial,
    this.trialEndsAt,
  });

  /// False for a copy not acquired from the Store (a sideloaded test
  /// package), which has nothing to enforce.
  final bool fromStore;
  final bool active;
  final bool trial;
  final DateTime? trialEndsAt;
}

/// What this copy of the app may do.
sealed class Entitlement {
  const Entitlement();

  /// Whether break reminders may run.
  bool get remindersAllowed => this is! TrialEnded;
}

/// No licensing applies: Linux, the Windows test zips and sideloaded test
/// packages, or a Store that has never answered.
class Unlimited extends Entitlement {
  const Unlimited();
}

/// The Store's free trial is running.
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

/// The app has been bought.
class Owned extends Entitlement {
  const Owned();

  @override
  bool operator ==(Object other) => other is Owned;

  @override
  int get hashCode => (Owned).hashCode;
}

/// The trial is over and the app has not been bought: reminders stop,
/// history stays. Windows itself refuses to start the app from then on, so
/// this is what a copy left running sees.
class TrialEnded extends Entitlement {
  const TrialEnded();
}

/// The one rule every licensing decision comes from.
///
/// The trial counts down on the wall clock to the end date the Store gave,
/// so it keeps ending on time while the PC is offline.
Entitlement entitlementFrom({
  required bool storeBuild,
  required StoreLicence? licence,
  required DateTime now,
}) {
  if (!storeBuild || licence == null || !licence.fromStore) {
    return const Unlimited();
  }
  if (!licence.trial) {
    return licence.active ? const Owned() : const TrialEnded();
  }
  final ends = licence.trialEndsAt;
  if (!licence.active || ends == null) return const TrialEnded();
  final left = ends.difference(now);
  if (left <= Duration.zero) return const TrialEnded();
  return Trial((left.inMinutes / Duration.minutesPerDay).ceil());
}
