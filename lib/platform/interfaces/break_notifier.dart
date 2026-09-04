// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/models/break_kind.dart';

/// What the user tapped on one of our notifications.
enum WarningAction { snooze, startNow, skip, returnToBreak }

/// Desktop notifications for the pre-break warning.
abstract interface class BreakNotifier {
  /// Shows (or replaces) the warning notification.
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
    required bool canSkip,
  });

  /// Removes the warning, e.g. when the break starts or is snoozed.
  Future<void> dismissWarning();

  /// Shows (or replaces) the notice that a break is on hold because the user
  /// switched away from the break screen. Lives in its own slot: it can never
  /// be on screen at the same time as a warning, but it must not be able to
  /// close one either.
  Future<void> showBreakHeld({required BreakKind kind});

  /// Removes the on-hold notice.
  Future<void> dismissBreakHeld();

  /// Actions invoked from the notification.
  Stream<WarningAction> get actions;

  /// One-off informational notification (e.g. an available update).
  Future<void> showInfo({required String title, required String body});

  Future<void> dispose();
}
