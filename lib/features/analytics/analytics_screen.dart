// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/charts.dart';
import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../data/rollup_repository.dart';
import '../../services/insights.dart';
import '../../services/providers.dart';
import 'rest_score_card.dart';

/// Weekly / monthly / yearly usage trends from daily rollups.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);
    final rollups = ref.watch(rangeRollupsProvider).value;
    final previous = ref.watch(previousRangeRollupsProvider).value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          children: [
            // Wraps rather than a Row with a Spacer: at narrow widths the
            // three-segment selector does not fit beside the heading, and a
            // Row simply overflows.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTokens.spaceMd,
              runSpacing: AppTokens.spaceMd,
              children: [
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
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
              RestScoreCard(rollups: rollups),
              const SizedBox(height: AppTokens.spaceMd),
              _StatTiles(rollups: rollups, previous: previous),
              const SizedBox(height: AppTokens.spaceLg),
              _CompositionCard(rollups: rollups, range: range),
              const SizedBox(height: AppTokens.spaceLg),
              _ComplianceCard(rollups: rollups, range: range),
              const SizedBox(height: AppTokens.spaceLg),
              _WhenYouWorkCard(rollups: rollups),
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

/// Whether a change is worth pointing out, and which way to read it.
///
/// Direction is not the same as goodness: more screen time is not a win,
/// and less is not a failure, so movement is shown neutrally and only
/// break-related figures carry a sense of better or worse.
enum Trend { up, down, flat }

typedef Tile = ({String label, String value, String? delta, Trend trend});

class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.rollups, required this.previous});

  final List<DayRollup> rollups;
  final List<DayRollup> previous;

  /// Percentage movement against the previous period, ignoring anything
  /// small enough to be noise.
  static (String?, Trend) _delta(num now, num before) {
    if (before == 0) return (null, Trend.flat);
    final change = (now - before) / before;
    if (change.abs() < 0.05) return ('no change', Trend.flat);
    final percent = (change.abs() * 100).round();
    return (
      '$percent% ${change > 0 ? 'more' : 'less'}',
      change > 0 ? Trend.up : Trend.down,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = summarise(rollups);
    final was = summarise(previous);
    final comparable = was.activeDays >= 3;

    (String?, Trend) against(num a, num b) =>
        comparable ? _delta(a, b) : (null, Trend.flat);

    final activeDelta = against(
      now.avgActive.inSeconds,
      was.avgActive.inSeconds,
    );
    final computerDelta = against(
      now.avgAtComputer.inSeconds,
      was.avgAtComputer.inSeconds,
    );
    final watchDelta = against(now.avgWatch.inSeconds, was.avgWatch.inSeconds);
    final stretchDelta = against(
      now.avgLongestStretch.inSeconds,
      was.avgLongestStretch.inSeconds,
    );
    final breaksDelta = against(now.breaksPerDay, was.breaksPerDay);
    final complianceDelta = against(now.compliance, was.compliance);

    final span = (now.typicalStartMinute == null)
        ? '—'
        : '${formatMinuteOfDay(now.typicalStartMinute!)}'
              ' – ${formatMinuteOfDay(now.typicalEndMinute!)}';

    final tiles = <Tile>[
      (
        label: 'Active / day',
        value: formatHoursMinutes(now.avgActive),
        delta: activeDelta.$1,
        trend: activeDelta.$2,
      ),
      (
        label: 'At computer / day',
        value: formatHoursMinutes(now.avgAtComputer),
        delta: computerDelta.$1,
        trend: computerDelta.$2,
      ),
      (
        label: 'Watching / day',
        value: formatHoursMinutes(now.avgWatch),
        delta: watchDelta.$1,
        trend: watchDelta.$2,
      ),
      (
        label: 'Hands-on share',
        value: formatPercent(now.activeShare),
        delta: null,
        trend: Trend.flat,
      ),
      (
        label: 'Longest run / day',
        value: formatHoursMinutes(now.avgLongestStretch),
        delta: stretchDelta.$1,
        trend: stretchDelta.$2,
      ),
      (
        label: 'Deep-work runs / day',
        value: now.focusRunsPerDay.toStringAsFixed(1),
        delta: null,
        trend: Trend.flat,
      ),
      (
        label: 'Breaks / day',
        value: now.breaksPerDay.toStringAsFixed(1),
        delta: breaksDelta.$1,
        trend: breaksDelta.$2,
      ),
      (
        label: 'Break compliance',
        value: formatPercent(now.compliance),
        delta: complianceDelta.$1,
        trend: complianceDelta.$2,
      ),
      (label: 'Typical day', value: span, delta: null, trend: Trend.flat),
      (
        label: 'Late & early / day',
        value: now.hasHourly ? formatHoursMinutes(now.avgAfterHours) : '—',
        delta: null,
        trend: Trend.flat,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          >= 900 => 5,
          >= 620 => 3,
          _ => 2,
        };
        final width =
            (constraints.maxWidth - AppTokens.spaceMd * (columns - 1)) /
            columns;
        return Wrap(
          spacing: AppTokens.spaceMd,
          runSpacing: AppTokens.spaceMd,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _Tile(tile)),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.tile);

  final Tile tile;

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
            Text(
              tile.label,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTokens.spaceSm),
            // Scaled down rather than clipped: a time range is much wider
            // than "4h 43m", and silently losing its second half made the
            // typical-day tile read as an unfinished sentence.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                tile.value,
                style: textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXs),
            // The arrow states the direction and the text repeats it, so the
            // movement is never carried by a glyph alone.
            Row(
              children: [
                if (tile.delta != null && tile.trend != Trend.flat)
                  Icon(
                    tile.trend == Trend.up
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 12,
                    color: scheme.outline,
                  ),
                Expanded(
                  child: Text(
                    tile.delta ?? '',
                    style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the time at the machine was made of, day by day.
class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.rollups, required this.range});

  final List<DayRollup> rollups;
  final AnalyticsRange range;

  /// One bar per day, or per month across a year — a 365-bar chart is a
  /// smear, not a trend.
  List<({String label, Map<ActivityBand, double> hours})> _points() {
    Map<ActivityBand, double> parts(Iterable<DayRollup> days, int divisor) => {
      ActivityBand.active:
          days.fold(0, (n, r) => n + r.screen.inSeconds) / 3600 / divisor,
      ActivityBand.watching:
          days.fold(0, (n, r) => n + r.watch.inSeconds) / 3600 / divisor,
      ActivityBand.idle:
          days.fold(0, (n, r) => n + r.idle.inSeconds) / 3600 / divisor,
      ActivityBand.away:
          days.fold(0, (n, r) => n + r.away.inSeconds) / 3600 / divisor,
    };

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
              hours: parts([r], 1),
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
              hours: parts(byMonth[key]!, byMonth[key]!.length),
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
        .map((p) => p.hours.values.fold(0.0, (a, b) => a + b))
        .fold(1.0, (a, b) => a > b ? a : b);

    return _ChartCard(
      title: range == AnalyticsRange.year
          ? 'A typical day, month by month'
          : 'Where each day went',
      legend: ActivityBand.values,
      child: BarChart(
        BarChartData(
          maxY: (maxHours * 1.15).ceilToDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, index, rod, _) => BarTooltipItem(
                [
                  for (final band in ActivityBand.values)
                    if ((points[index].hours[band] ?? 0) > 0.01)
                      '${band.label} '
                          '${formatHoursMinutes(Duration(minutes: (points[index].hours[band]! * 60).round()))}',
                ].join('\n'),
                textTheme.labelMedium!.copyWith(color: scheme.onInverseSurface),
              ),
            ),
          ),
          titlesData: _titles(context, points.length, (i) => points[i].label),
          gridData: _grid(scheme),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (final (i, p) in points.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: p.hours.values.fold(0.0, (a, b) => a + b),
                    width: range == AnalyticsRange.month ? 6 : 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    rodStackItems: _stack(p.hours, scheme),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Stacked from the baseline up in band order, so the ramp always runs
  /// dark to pale in the same direction as the legend.
  List<BarChartRodStackItem> _stack(
    Map<ActivityBand, double> hours,
    ColorScheme scheme,
  ) {
    final items = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final band in ActivityBand.values) {
      final value = hours[band] ?? 0;
      if (value <= 0) continue;
      items.add(BarChartRodStackItem(from, from + value, band.color(scheme)));
      from += value;
    }
    return items;
  }
}

/// Whether breaks that came due were actually taken, day by day.
class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.rollups, required this.range});

  final List<DayRollup> rollups;
  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final points = [
      for (final r in rollups)
        (
          label: range == AnalyticsRange.week
              ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][r.day.weekday - 1]
              : '${r.day.day}',
          value: () {
            final concluded = r.completed + r.credited + r.escaped;
            return concluded == 0
                ? null
                : (r.completed + r.credited) / concluded * 100;
          }(),
        ),
    ];

    if (points.every((p) => p.value == null)) return const SizedBox.shrink();

    return _ChartCard(
      title: 'Breaks actually taken',
      subtitle: 'Share of due breaks you rested, day by day',
      child: BarChart(
        BarChartData(
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, index, rod, _) => BarTooltipItem(
                '${rod.toY.round()}%',
                textTheme.labelMedium!.copyWith(color: scheme.onInverseSurface),
              ),
            ),
          ),
          titlesData: _titles(
            context,
            points.length,
            (i) => points[i].label,
            leftLabel: (v) => '${v.toInt()}%',
            leftInterval: 50,
          ),
          gridData: _grid(scheme, interval: 50),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (final (i, p) in points.indexed)
              if (p.value != null)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: p.value!,
                      width: range == AnalyticsRange.month ? 6 : 14,
                      color: scheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 100,
                        color: scheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

/// The week as a grid: which hours of which days you are actually at this
/// machine. Answers "when do I work", which no total can.
class _WhenYouWorkCard extends StatelessWidget {
  const _WhenYouWorkCard({required this.rollups});

  final List<DayRollup> rollups;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final grid = weekdayHourProfile(rollups);

    if (grid.isEmpty) return const SizedBox.shrink();

    final peak = grid
        .expand((row) => row)
        .fold(0.0, (a, b) => a > b ? a : b)
        .clamp(1.0, 3600.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('When you work', style: textTheme.titleMedium),
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              'Average hands-on time in each hour, by day of the week',
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            for (final (weekday, row) in grid.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        _days[weekday],
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (final (hour, seconds) in row.indexed)
                      Expanded(
                        child: Tooltip(
                          message:
                              '${_days[weekday]} ${formatMinuteOfDay(hour * 60)}'
                              '\n${formatMinutes(Duration(seconds: seconds.round()))} hands-on',
                          child: Container(
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              // One hue, light to dark: a magnitude, so a
                              // rainbow would invent categories that are not
                              // there.
                              color: seconds <= 0
                                  ? scheme.surfaceContainerHighest
                                  : scheme.primary.withValues(
                                      alpha: 0.15 + 0.85 * (seconds / peak),
                                    ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.spaceXs),
            // Bounded, because an OverflowBox inside a Column has no height
            // to overflow from and asserts instead.
            SizedBox(
              height: 16,
              child: Row(
                children: [
                  const SizedBox(width: 34),
                  for (var hour = 0; hour < 24; hour++)
                    Expanded(
                      child: hour % 6 == 0
                          ? OverflowBox(
                              alignment: Alignment.topLeft,
                              maxWidth: 60,
                              child: Text(
                                formatMinuteOfDay(hour * 60),
                                maxLines: 1,
                                softWrap: false,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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

/// Shared chrome for the fl_chart cards: title, optional legend, fixed
/// plot height.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.legend = const [],
  });

  final String title;
  final String? subtitle;
  final List<ActivityBand> legend;
  final Widget child;

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
            Text(title, style: textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppTokens.spaceXs),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
            const SizedBox(height: AppTokens.spaceLg),
            SizedBox(height: 220, child: child),
            if (legend.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spaceMd),
              Wrap(
                spacing: AppTokens.spaceMd,
                runSpacing: AppTokens.spaceSm,
                children: [
                  for (final band in legend)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: band.color(scheme),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceXs),
                        Text(
                          band.label,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

FlGridData _grid(ColorScheme scheme, {double? interval}) => FlGridData(
  drawVerticalLine: false,
  horizontalInterval: interval,
  getDrawingHorizontalLine: (_) => FlLine(
    color: scheme.outlineVariant.withValues(alpha: 0.4),
    strokeWidth: 1,
  ),
);

FlTitlesData _titles(
  BuildContext context,
  int count,
  String Function(int index) label, {
  String Function(double value)? leftLabel,
  double? leftInterval,
}) {
  final textTheme = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;
  final style = textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);

  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        interval: leftInterval,
        getTitlesWidget: (value, _) =>
            Text(leftLabel?.call(value) ?? '${value.toInt()}h', style: style),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (i < 0 || i >= count) return const SizedBox.shrink();
          // Crowded ranges label every fifth bar; all of them is a smudge.
          if (count > 14 && i % 5 != 0) return const SizedBox.shrink();
          return Text(label(i), style: style);
        },
      ),
    ),
  );
}
