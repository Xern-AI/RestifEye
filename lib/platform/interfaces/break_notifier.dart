// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../../core/models/break_kind.dart';

/// What the user tapped on a pre-break warning notification.
enum WarningAction { snooze, startNow, skip }

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

  /// Actions invoked from the notification.
  Stream<WarningAction> get actions;

  /// One-off informational notification (e.g. an available update).
  Future<void> showInfo({required String title, required String body});

  Future<void> dispose();
}
