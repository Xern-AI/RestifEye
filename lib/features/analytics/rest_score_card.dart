// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/rollup_repository.dart';
import '../../services/insights.dart';
import '../../services/providers.dart';

/// The headline answer to "how am I doing", with the parts that made it and
/// the one worth fixing next.
///
/// A single number invites the question "made of what?", so the components
/// are shown as bars beside it rather than hidden behind it — and the
/// weakest is named in words, because a bar chart alone does not tell
/// anybody what to change.
class RestScoreCard extends ConsumerWidget {
  const RestScoreCard({super.key, required this.rollups});

  final List<DayRollup> rollups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(breakConfigProvider);
    final score = scorePeriod(rollups, config);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (score == null) {
      return Card(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppTokens.spaceMd),
              Expanded(
                child: Text(
                  'A rest score needs at least three days of use in this '
                  'range. One day is not a habit.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weakest = score.weakest;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headline = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest score',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${score.total}',
                      style: textTheme.displayMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceXs),
                    Text(
                      '/ 100',
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  score.band,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            );

            final parts = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final part in score.parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.spaceSm),
                    child: _PartBar(part: part),
                  ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (constraints.maxWidth >= 560)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 180, child: headline),
                      const SizedBox(width: AppTokens.spaceLg),
                      Expanded(child: parts),
                    ],
                  )
                else ...[
                  headline,
                  const SizedBox(height: AppTokens.spaceLg),
                  parts,
                ],
                if (weakest != null && weakest.value < 0.9) ...[
                  const SizedBox(height: AppTokens.spaceSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppTokens.spaceSm),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Biggest gain available: ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              TextSpan(text: weakest.advice),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PartBar extends StatelessWidget {
  const _PartBar({required this.part});

  final ScorePart part;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ink = scheme.onPrimaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                part.label,
                style: textTheme.labelMedium?.copyWith(color: ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSm),
            // Flexible, not bare: the detail line is a sentence, and at
            // narrow widths an unbounded one pushes straight off the card.
            Flexible(
              child: Text(
                part.detail,
                style: textTheme.bodySmall?.copyWith(
                  color: ink.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceXs),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: part.value,
            minHeight: 6,
            backgroundColor: ink.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(ink.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}
