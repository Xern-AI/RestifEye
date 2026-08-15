// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../app/charts.dart';
import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../core/models/activity.dart';

/// The day as twenty-four stacked columns: what each hour was made of.
///
/// A column is as tall as the part of that hour we have any record for, so
/// the shape of the working day — the late start, the lunch gap, the evening
/// that ran on — is visible without reading a single number. Totals answer
/// "how much"; only this answers "when".
class DayShape extends StatelessWidget {
  const DayShape({super.key, required this.hours, this.height = 96});

  final List<HourBand> hours;
  final double height;

  static const _labelledHours = {0, 6, 12, 18};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (hours.length != 24) return const SizedBox.shrink();
    final recorded = hours.any((h) => hourTotal(h) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shape of your day', style: textTheme.titleMedium),
        const SizedBox(height: AppTokens.spaceMd),
        SizedBox(
          height: height,
          child: recorded
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (hour, band) in hours.indexed)
                      Expanded(
                        child: _HourColumn(
                          hour: hour,
                          band: band,
                          height: height,
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Text(
                    'Nothing recorded yet today.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppTokens.spaceXs),
        // A label is wider than the hour it belongs to, so it is allowed to
        // spill sideways instead of wrapping into "00:0 / 0".
        SizedBox(
          height: 16,
          child: Row(
            children: [
              for (var hour = 0; hour < 24; hour++)
                Expanded(
                  child: _labelledHours.contains(hour)
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
        const SizedBox(height: AppTokens.spaceMd),
        // Four bands of one hue need the legend to say which is which; the
        // stacking order alone would leave the reader guessing.
        Wrap(
          spacing: AppTokens.spaceMd,
          runSpacing: AppTokens.spaceSm,
          children: [
            for (final band in ActivityBand.values)
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
    );
  }
}

class _HourColumn extends StatelessWidget {
  const _HourColumn({
    required this.hour,
    required this.band,
    required this.height,
  });

  final int hour;
  final HourBand band;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = hourTotal(band);

    const gap = 1.5;
    // Reversed, so hands-on work sits on the baseline and the emptier states
    // stack above it. Built the other way up the bars appear to hang.
    final present = [
      for (final kind in ActivityBand.values.reversed)
        if (kind.secondsIn(band) > 0) kind,
    ];

    // The segments plus their separators have to fit the column exactly. A
    // recorded minute must never round away to nothing — a short spell at
    // the desk should not look identical to being out of the room — so every
    // band gets a visible floor, and the whole stack is scaled back down if
    // those floors have pushed it past the budget.
    final budget = height - gap * (present.length - 1);
    final sizes = [
      for (final kind in present)
        (kind.secondsIn(band) / 3600 * budget).clamp(2.0, budget),
    ];
    final stacked = sizes.fold(0.0, (sum, size) => sum + size);
    final scale = stacked > budget ? budget / stacked : 1.0;

    return Tooltip(
      message: _summary(total),
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: present.isEmpty
              ? [
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: gap),
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ]
              : [
                  for (final (i, kind) in present.indexed) ...[
                    SizedBox(
                      height: sizes[i] * scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: gap),
                        decoration: BoxDecoration(
                          color: kind.color(scheme),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (i < present.length - 1) const SizedBox(height: gap),
                  ],
                ],
        ),
      ),
    );
  }

  String _summary(int total) {
    final at = formatMinuteOfDay(hour * 60);
    if (total == 0) return '$at  ·  nothing recorded';
    final parts = [
      for (final kind in ActivityBand.values)
        if (kind.secondsIn(band) > 0)
          '${kind.label} ${formatMinutes(Duration(seconds: kind.secondsIn(band)))}',
    ];
    return '$at\n${parts.join('\n')}';
  }
}
