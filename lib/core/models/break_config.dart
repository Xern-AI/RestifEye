import 'break_kind.dart';

/// Engine configuration. Immutable; times of day are minutes since midnight
/// so `core/` stays free of Flutter types.
class BreakConfig {
  const BreakConfig({
    this.microInterval = const Duration(minutes: 20),
    this.microDuration = const Duration(seconds: 20),
    this.longInterval = const Duration(minutes: 50),
    this.longDuration = const Duration(minutes: 5),
    this.warningLead = const Duration(seconds: 30),
    this.snoozeBudget = 3,
    this.snoozeLength = const Duration(minutes: 2),
    this.deferRecheck = const Duration(minutes: 5),
    this.deferCap = const Duration(minutes: 15),
    this.idleFireThreshold = const Duration(minutes: 2),
    this.workStartMinutes = 0,
    this.workEndMinutes = 24 * 60,
    this.workDays = const {1, 2, 3, 4, 5, 6, 7},
    this.strictMode = true,
  }) : assert(snoozeBudget >= 0),
       assert(workStartMinutes >= 0 && workStartMinutes <= 24 * 60),
       assert(workEndMinutes >= 0 && workEndMinutes <= 24 * 60);

  final Duration microInterval;
  final Duration microDuration;
  final Duration longInterval;
  final Duration longDuration;

  /// Heads-up notification lead time before a break takes over.
  final Duration warningLead;

  /// Snoozes allowed per break before strict mode engages.
  final int snoozeBudget;
  final Duration snoozeLength;

  /// While busy (call/DND), re-check at this interval...
  final Duration deferRecheck;

  /// ...but never delay a due break by more than this in total.
  final Duration deferCap;

  /// Breaks don't fire while the user is already away at least this long;
  /// the away span is credited on return instead.
  final Duration idleFireThreshold;

  /// Work window (minutes since midnight). Outside it the engine pauses.
  final int workStartMinutes;
  final int workEndMinutes;

  /// ISO weekday numbers (1 = Monday ... 7 = Sunday) the engine runs on.
  final Set<int> workDays;

  final bool strictMode;

  Duration interval(BreakKind kind) =>
      kind == BreakKind.micro ? microInterval : longInterval;

  Duration breakDuration(BreakKind kind) =>
      kind == BreakKind.micro ? microDuration : longDuration;

  /// Whether [now] falls inside the configured work window.
  bool isWithinWorkHours(DateTime now) {
    if (!workDays.contains(now.weekday)) return false;
    final minutes = now.hour * 60 + now.minute;
    if (workStartMinutes <= workEndMinutes) {
      return minutes >= workStartMinutes && minutes < workEndMinutes;
    }
    // Overnight window (e.g. 22:00 – 06:00).
    return minutes >= workStartMinutes || minutes < workEndMinutes;
  }

  BreakConfig copyWith({
    Duration? microInterval,
    Duration? microDuration,
    Duration? longInterval,
    Duration? longDuration,
    Duration? warningLead,
    int? snoozeBudget,
    Duration? snoozeLength,
    Duration? deferRecheck,
    Duration? deferCap,
    Duration? idleFireThreshold,
    int? workStartMinutes,
    int? workEndMinutes,
    Set<int>? workDays,
    bool? strictMode,
  }) {
    return BreakConfig(
      microInterval: microInterval ?? this.microInterval,
      microDuration: microDuration ?? this.microDuration,
      longInterval: longInterval ?? this.longInterval,
      longDuration: longDuration ?? this.longDuration,
      warningLead: warningLead ?? this.warningLead,
      snoozeBudget: snoozeBudget ?? this.snoozeBudget,
      snoozeLength: snoozeLength ?? this.snoozeLength,
      deferRecheck: deferRecheck ?? this.deferRecheck,
      deferCap: deferCap ?? this.deferCap,
      idleFireThreshold: idleFireThreshold ?? this.idleFireThreshold,
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      workDays: workDays ?? this.workDays,
      strictMode: strictMode ?? this.strictMode,
    );
  }
}
