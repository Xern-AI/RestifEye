import '../../core/models/break_kind.dart';

/// What the user tapped on a pre-break warning notification.
enum WarningAction { snooze, startNow }

/// Desktop notifications for the pre-break warning.
abstract interface class BreakNotifier {
  /// Shows (or replaces) the warning notification.
  Future<void> showWarning({
    required BreakKind kind,
    required Duration startsIn,
    required bool canSnooze,
  });

  /// Removes the warning, e.g. when the break starts or is snoozed.
  Future<void> dismissWarning();

  /// Actions invoked from the notification.
  Stream<WarningAction> get actions;

  /// One-off informational notification (e.g. an available update).
  Future<void> showInfo({required String title, required String body});

  Future<void> dispose();
}
