// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../core/engine/phase.dart';
import '../../core/models/break_kind.dart';
import '../../services/providers.dart';

/// Today at a glance: live next-break countdown and today's stats.
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
            const _TodayStatsRow(),
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

/// Today's numbers.
///
/// Idle and away time were already being recorded every second and thrown
/// away at the aggregation step; they answer the question screen time alone
/// cannot — how much of the day was actually spent at this machine.
///
/// Wraps rather than scrolls sideways, so nothing is hidden at narrow widths.
class _TodayStatsRow extends ConsumerWidget {
  const _TodayStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(todaySliceStatsProvider).value;
    final counts = ref.watch(todayBreakCountsProvider).value;

    String dur(Duration? d) => d == null ? '—' : formatHoursMinutes(d);

    final span = switch ((stats?.firstActivity, stats?.lastActivity)) {
      (final DateTime first, final DateTime last) =>
        '${formatMinuteOfDay(first.hour * 60 + first.minute)}'
            ' – ${formatMinuteOfDay(last.hour * 60 + last.minute)}',
      _ => '—',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across when there is room, two when there is not.
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        final width =
            (constraints.maxWidth - AppTokens.spaceMd * (columns - 1)) /
            columns;

        return Wrap(
          spacing: AppTokens.spaceMd,
          runSpacing: AppTokens.spaceMd,
          children: [
            for (final card in [
              (
                label: 'Active',
                value: dur(stats?.screenTime),
                hint: 'Typing and clicking',
              ),
              (
                label: 'At computer',
                value: dur(stats?.atComputer),
                hint: stats == null
                    ? null
                    : '${formatPercent(stats.activeRatio)} of it active',
              ),
              (
                label: 'Idle',
                value: dur(stats?.idleTime),
                hint: 'Here, but hands off',
              ),
              (
                label: 'Away',
                value: dur(stats?.awayTime),
                hint: 'Locked or suspended',
              ),
              (
                label: 'Longest focus',
                value: dur(stats?.longestStretch),
                hint: 'Unbroken stretch',
              ),
              (
                label: 'Breaks taken',
                value: counts == null
                    ? '—'
                    : '${counts.completed + counts.credited}',
                hint: span == '—' ? null : 'Day ran $span',
              ),
            ])
              SizedBox(
                width: width,
                child: _StatCard(
                  label: card.label,
                  value: card.value,
                  hint: card.hint,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelMedium),
            const SizedBox(height: AppTokens.spaceSm),
            Text(value, style: textTheme.headlineSmall),
            if (hint != null) ...[
              const SizedBox(height: AppTokens.spaceXs),
              Text(
                hint!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
