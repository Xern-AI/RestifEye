// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../data/rollup_repository.dart';
import '../../services/providers.dart';

/// Weekly / monthly / yearly usage trends from daily rollups.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final rollups = ref.watch(rangeRollupsProvider).value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          children: [
            Row(
              children: [
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                SegmentedButton<AnalyticsRange>(
                  segments: const [
                    ButtonSegment(
                      value: AnalyticsRange.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: AnalyticsRange.month,
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: AnalyticsRange.year,
                      label: Text('Year'),
                    ),
                  ],
                  selected: {range},
                  onSelectionChanged: (selection) => ref
                      .read(analyticsRangeProvider.notifier)
                      .select(selection.first),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceLg),
            if (rollups == null || rollups.isEmpty)
              const _EmptyAnalytics()
            else ...[
              _StatTiles(rollups: rollups),
              const SizedBox(height: AppTokens.spaceLg),
              _ScreenTimeCard(rollups: rollups, range: range),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 96),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppTokens.spaceMd),
          Text(
            'Your screen-time and break trends will appear here\n'
            'after your first full day of use.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.rollups});

  final List<DayRollup> rollups;

  @override
  Widget build(BuildContext context) {
    final active = rollups.where((r) => r.screen > Duration.zero).toList();
    final days = active.isEmpty ? 1 : active.length;

    Duration avg(int Function(DayRollup) seconds) =>
        Duration(seconds: active.fold(0, (n, r) => n + seconds(r)) ~/ days);

    final avgScreen = avg((r) => r.screen.inSeconds);
    final avgAtComputer = avg((r) => atComputerOf(r).inSeconds);
    final avgAway = avg((r) => r.away.inSeconds);
    final avgStretch = avg((r) => r.longestStretch.inSeconds);

    final activeRatio = avgAtComputer.inSeconds == 0
        ? 0.0
        : avgScreen.inSeconds / avgAtComputer.inSeconds;

    final taken = active.fold(0, (n, r) => n + r.completed + r.credited);
    final concluded = taken + active.fold(0, (n, r) => n + r.escaped);
    final compliance = concluded == 0 ? 100 : (taken * 100 ~/ concluded);

    // Average start/end of the working day, over the days that recorded one.
    final withSpan = active
        .where((r) => r.firstActivityMinute != null)
        .toList();
    final span = withSpan.isEmpty
        ? '-'
        : '${formatMinuteOfDay(withSpan.fold(0, (n, r) => n + r.firstActivityMinute!) ~/ withSpan.length)}'
              ' - ${formatMinuteOfDay(withSpan.fold(0, (n, r) => n + r.lastActivityMinute!) ~/ withSpan.length)}';

    final tiles = <({String label, String value})>[
      (label: 'Avg active / day', value: formatHoursMinutes(avgScreen)),
      (label: 'Avg at computer', value: formatHoursMinutes(avgAtComputer)),
      (label: 'Active share', value: formatPercent(activeRatio)),
      (label: 'Avg away', value: formatHoursMinutes(avgAway)),
      (label: 'Longest focus', value: formatHoursMinutes(avgStretch)),
      (label: 'Typical day', value: span),
      (label: 'Break compliance', value: '$compliance%'),
      (label: 'Breaks / day', value: (taken / days).toStringAsFixed(1)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppTokens.spaceMd * (columns - 1)) /
            columns;
        return Wrap(
          spacing: AppTokens.spaceMd,
          runSpacing: AppTokens.spaceMd,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: width,
                child: _Tile(label: tile.label, value: tile.value),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});

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

/// Single-series magnitude chart: screen time per day (week/month) or per
/// month (year). One hue, thin rounded bars, tooltip on hover.
class _ScreenTimeCard extends StatelessWidget {
  const _ScreenTimeCard({required this.rollups, required this.range});

  final List<DayRollup> rollups;
  final AnalyticsRange range;

  List<({String label, Duration screen})> _points() {
    switch (range) {
      case AnalyticsRange.week:
      case AnalyticsRange.month:
        const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return [
          for (final r in rollups)
            (
              label: range == AnalyticsRange.week
                  ? dayNames[r.day.weekday - 1]
                  : '${r.day.day}',
              screen: r.screen,
            ),
        ];
      case AnalyticsRange.year:
        final byMonth = <int, List<DayRollup>>{};
        for (final r in rollups) {
          byMonth.putIfAbsent(r.day.year * 12 + r.day.month, () => []).add(r);
        }
        const monthNames = [
          'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D', //
        ];
        final keys = byMonth.keys.toList()..sort();
        return [
          for (final key in keys)
            (
              label: monthNames[(key - 1) % 12],
              screen: Duration(
                seconds:
                    byMonth[key]!.fold(0, (n, r) => n + r.screen.inSeconds) ~/
                    byMonth[key]!.length,
              ),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final points = _points();
    final maxHours = points
        .map((p) => p.screen.inMinutes / 60)
        .fold(1.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              range == AnalyticsRange.year
                  ? 'Average screen time per day, by month'
                  : 'Screen time per day',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spaceLg),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: (maxHours * 1.2).ceilToDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        formatHoursMinutes(
                          Duration(minutes: (rod.toY * 60).round()),
                        ),
                        textTheme.labelLarge!.copyWith(
                          color: scheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}h',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          // Month view: label every 5th day to avoid clutter.
                          if (range == AnalyticsRange.month && i % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            points[i].label,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (final (i, p) in points.indexed)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: p.screen.inMinutes / 60,
                            width: range == AnalyticsRange.month ? 6 : 14,
                            color: scheme.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
