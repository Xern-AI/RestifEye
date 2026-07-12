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

    final (label, value) = switch (phase.value) {
      Monitoring(:final nextBreakIn, :final nextBreakKind) => (
        nextBreakKind == BreakKind.micro ? 'Next eye break' : 'Next long break',
        formatCountdown(nextBreakIn),
      ),
      Warning(:final startsIn) => (
        'Break starting',
        'in ${startsIn.inSeconds}s',
      ),
      InBreak(:final remaining) => (
        'Break in progress',
        formatCountdown(remaining),
      ),
      Deferred() => ('Break waiting', 'until your call ends'),
      Paused(:final byUser) => (
        'Paused',
        byUser ? 'by you' : 'outside work hours',
      ),
      null => ('Starting up', '…'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayStatsRow extends ConsumerWidget {
  const _TodayStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slices = ref.watch(todaySliceStatsProvider).value;
    final counts = ref.watch(todayBreakCountsProvider).value;

    final screenTime = slices == null
        ? '—'
        : formatHoursMinutes(slices.screenTime);
    final stretch = slices == null
        ? '—'
        : formatHoursMinutes(slices.longestStretch);
    final breaks = counts == null
        ? '—'
        : '${counts.completed + counts.credited}';

    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Screen time', value: screenTime),
        ),
        const SizedBox(width: AppTokens.spaceMd),
        Expanded(
          child: _StatCard(label: 'Breaks taken', value: breaks),
        ),
        const SizedBox(width: AppTokens.spaceMd),
        Expanded(
          child: _StatCard(label: 'Longest focus', value: stretch),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.labelMedium),
            const SizedBox(height: AppTokens.spaceSm),
            Text(value, style: textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
