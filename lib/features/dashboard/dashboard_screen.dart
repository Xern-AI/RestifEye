// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../core/engine/phase.dart';
import '../../core/models/activity.dart';
import '../../core/models/break_kind.dart';
import '../../services/insights.dart';
import '../../services/providers.dart';
import 'day_shape.dart';

/// Today at a glance: the live countdown, the shape the day has taken, and
/// the numbers behind it — grouped, because a flat grid of a dozen equal
/// cards makes the reader do the sorting.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          children: [
            Text('Today', style: textTheme.headlineMedium),
            const SizedBox(height: AppTokens.spaceLg),
            const _NextBreakCard(),
            const SizedBox(height: AppTokens.spaceSm),
            const _PauseControl(),
            const SizedBox(height: AppTokens.spaceMd),
            const _DayShapeCard(),
            const SizedBox(height: AppTokens.spaceMd),
            const _TimeGroup(),
            const SizedBox(height: AppTokens.spaceMd),
            const _FocusGroup(),
            const SizedBox(height: AppTokens.spaceMd),
            const _BreaksGroup(),
          ],
        ),
      ),
    );
  }
}

class _NextBreakCard extends ConsumerWidget {
  const _NextBreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(enginePhaseProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Secondary line: the countdown for the *other* timer, so both the eye
    // and the long break are always visible while monitoring.
    final (label, value, secondary) = switch (phase.value) {
      Monitoring(
        :final nextBreakIn,
        :final nextBreakKind,
        :final microIn,
        :final longIn,
      ) =>
        nextBreakKind == BreakKind.micro
            ? (
                'Next eye break',
                formatCountdown(nextBreakIn),
                'Long break in ${formatCountdown(longIn)}',
              )
            : (
                'Next long break',
                formatCountdown(nextBreakIn),
                microIn <= longIn
                    ? 'Eye break folds into the long break'
                    : 'Eye break in ${formatCountdown(microIn)}',
              ),
      Warning(:final startsIn) => (
        'Break starting',
        'in ${startsIn.inSeconds}s',
        null,
      ),
      InBreak(:final remaining) => (
        'Break in progress',
        formatCountdown(remaining),
        null,
      ),
      Deferred() => ('Break waiting', 'until your call ends', null),
      Paused(:final reason, :final byApp) => (
        'Paused',
        switch (reason) {
          PauseReason.user => 'by you',
          PauseReason.workHours => 'outside work hours',
          PauseReason.media =>
            byApp == null
                ? 'while something is playing'
                : 'while $byApp is playing',
        },
        null,
      ),
      null => ('Starting up', '…', null),
    };

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 40,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: AppTokens.spaceXs),
                    Text(
                      secondary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pause breaks for a bounded stretch — a meeting, a demo, deep work.
///
/// Timed by default and capped at three hours. An open-ended pause is offered
/// but not encouraged: the failure mode of a break reminder is being silenced
/// "just for now" and never switched back on, and the user never finds out.
class _PauseControl extends ConsumerWidget {
  const _PauseControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pause = ref.watch(pausedProvider);
    final notifier = ref.read(pausedProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!pause.paused) {
      return Align(
        alignment: Alignment.centerLeft,
        child: MenuAnchor(
          menuChildren: [
            for (final option in PauseDuration.values)
              MenuItemButton(
                onPressed: () => notifier.pause(option),
                child: Text(option.label),
              ),
          ],
          builder: (context, controller, _) => TextButton.icon(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: const Icon(Icons.pause_circle_outline),
            label: const Text('Pause breaks'),
          ),
        ),
      );
    }

    // Re-reading the live phase keeps the countdown ticking with the engine.
    final phase = ref.watch(enginePhaseProvider).value;
    final until = switch (phase) {
      Paused(:final until) => until,
      _ => pause.until,
    };
    final remaining = until?.difference(DateTime.now());

    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Row(
          children: [
            Icon(Icons.pause_circle, color: scheme.onTertiaryContainer),
            const SizedBox(width: AppTokens.spaceMd),
            Expanded(
              child: Text(
                remaining == null || remaining.isNegative
                    ? 'Paused until you resume'
                    : 'Paused · resumes in ${formatCountdown(remaining)}',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: notifier.resume,
              child: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayShapeCard extends ConsumerWidget {
  const _DayShapeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todaySliceStatsProvider).value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: DayShape(hours: stats?.hours ?? const []),
      ),
    );
  }
}

/// Where the day went.
class _TimeGroup extends ConsumerWidget {
  const _TimeGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todaySliceStatsProvider).value;
    final history = ref.watch(recentRollupsProvider).value ?? const [];
    final now = ref.watch(wallClockProvider)();

    final pace = stats == null
        ? null
        : paceAgainstTypical(
            today: stats.hours,
            history: history,
            completedHours: now.hour,
          );

    return _MetricGroup(
      title: 'Time',
      icon: Icons.schedule_outlined,
      metrics: [
        (
          label: 'Active',
          value: _duration(stats?.screenTime),
          hint: _paceHint(pace),
        ),
        (
          label: 'At computer',
          value: _duration(stats?.atComputer),
          hint: stats == null
              ? null
              : '${formatPercent(stats.activeRatio)} of it hands-on',
        ),
        (
          label: 'Watching',
          value: _duration(stats?.watchTime),
          hint: 'Video, calls, slides',
        ),
        (label: 'Idle', value: _duration(stats?.idleTime), hint: 'Hands off'),
        (
          label: 'Away',
          value: _duration(stats?.awayTime),
          hint: 'Locked or suspended',
        ),
      ],
    );
  }

  /// Reads as encouragement either way: this is a rest app, so a shorter day
  /// than usual is not a failure to report.
  static String? _paceHint(Pace? pace) {
    if (pace == null) return null;
    final minutes = pace.difference.inMinutes;
    if (minutes.abs() < 10) return 'On par with your usual';
    final size = formatHoursMinutes(Duration(minutes: minutes.abs()));
    return minutes > 0 ? '$size more than usual' : '$size less than usual';
  }
}

/// How the work itself was shaped.
class _FocusGroup extends ConsumerWidget {
  const _FocusGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todaySliceStatsProvider).value;

    final span = switch ((stats?.firstActivity, stats?.lastActivity)) {
      (final DateTime first, final DateTime last) =>
        '${formatMinuteOfDay(first.hour * 60 + first.minute)}'
            ' – ${formatMinuteOfDay(last.hour * 60 + last.minute)}',
      _ => '—',
    };
    final peak = stats?.peakHour;

    return _MetricGroup(
      title: 'Focus',
      icon: Icons.center_focus_strong_outlined,
      metrics: [
        (
          label: 'Longest stretch',
          value: _duration(stats?.longestStretch),
          hint: 'Without a pause',
        ),
        (
          label: 'Deep-work runs',
          value: stats == null ? '—' : '${stats.focusRuns}',
          hint: 'Over ${focusRunMinimum.inMinutes} minutes',
        ),
        (
          label: 'Busiest hour',
          value: peak == null ? '—' : formatMinuteOfDay(peak * 60),
          hint: peak == null ? null : 'Most hands-on time',
        ),
        (label: 'Day ran', value: span, hint: 'First to last activity'),
        (
          label: 'Late & early',
          value: _duration(stats?.afterHours),
          hint: 'Before 07:00 or after 22:00',
        ),
      ],
    );
  }
}

/// Whether the app's whole purpose is being served.
class _BreaksGroup extends ConsumerWidget {
  const _BreaksGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(todayBreakCountsProvider).value;
    final stats = ref.watch(todaySliceStatsProvider).value;

    final taken = counts == null ? null : counts.completed + counts.credited;
    final concluded = counts == null
        ? 0
        : counts.completed + counts.credited + counts.escaped;
    final missed = counts == null ? null : counts.escaped + counts.skipped;

    // Rest per hour actually at the machine: the number that says whether
    // the schedule is being honoured, independent of how long the day was.
    final atComputerHours = (stats?.atComputer.inMinutes ?? 0) / 60;
    final perHour = taken == null || atComputerHours < 0.5
        ? '—'
        : (taken / atComputerHours).toStringAsFixed(1);

    return _MetricGroup(
      title: 'Breaks',
      icon: Icons.self_improvement_outlined,
      metrics: [
        (
          label: 'Taken',
          value: taken == null ? '—' : '$taken',
          hint: counts == null || counts.credited == 0
              ? 'Completed or credited'
              : '${counts.credited} by walking away',
        ),
        (
          label: 'Followed through',
          value: concluded == 0 ? '—' : formatPercent((taken ?? 0) / concluded),
          hint: 'Of breaks that came due',
        ),
        (
          label: 'Per hour',
          value: perHour,
          hint: 'Rests per hour at the machine',
        ),
        (
          label: 'Snoozed',
          value: counts == null ? '—' : '${counts.snoozes}',
          hint: 'Pushed back, then taken',
        ),
        (
          label: 'Skipped',
          value: missed == null ? '—' : '$missed',
          hint: 'From the warning or mid-break',
        ),
      ],
    );
  }
}

String _duration(Duration? d) => d == null ? '—' : formatHoursMinutes(d);

typedef _Metric = ({String label, String value, String? hint});

/// A titled group of related numbers in one card.
///
/// One card per group rather than one per number: the borders then mean
/// something (these belong together) instead of being a uniform grid the
/// reader has to parse from scratch.
class _MetricGroup extends StatelessWidget {
  const _MetricGroup({
    required this.title,
    required this.icon,
    required this.metrics,
  });

  final String title;
  final IconData icon;
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppTokens.spaceSm),
                Text(title, style: textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTokens.spaceLg),
            LayoutBuilder(
              builder: (context, constraints) {
                // Wraps rather than scrolls sideways, so nothing is hidden
                // at narrow widths.
                final columns = switch (constraints.maxWidth) {
                  >= 820 => 5,
                  >= 560 => 3,
                  _ => 2,
                };
                final width =
                    (constraints.maxWidth - AppTokens.spaceMd * (columns - 1)) /
                    columns;
                return Wrap(
                  spacing: AppTokens.spaceMd,
                  runSpacing: AppTokens.spaceLg,
                  children: [
                    for (final metric in metrics)
                      SizedBox(width: width, child: _MetricView(metric)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricView extends StatelessWidget {
  const _MetricView(this.metric);

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metric.label,
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTokens.spaceXs),
        Text(
          metric.value,
          style: textTheme.headlineSmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
        ),
        if (metric.hint != null) ...[
          const SizedBox(height: AppTokens.spaceXs),
          Text(
            metric.hint!,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            maxLines: 2,
          ),
        ],
      ],
    );
  }
}
