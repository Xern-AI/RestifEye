// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/formats.dart';
import '../../app/theme.dart';
import '../../core/engine/phase.dart';
import '../../core/models/break_kind.dart';
import '../../services/break_session.dart';
import '../../services/providers.dart';
import '../exercises/exercise_figure.dart';
import 'hold_to_skip.dart';

/// Break takeover screen: exercise, countdown ring, and the logged
/// hold-to-skip escape. Snoozing and skipping live in the pre-break
/// notification — once the overlay is up, the break has begun.
class BreakOverlay extends ConsumerWidget {
  const BreakOverlay({super.key, required this.phase});

  final InBreak phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final exercise = ref.watch(breakSessionProvider);
    final engine = ref.watch(engineServiceProvider).engine;
    final total = engine.config.breakDuration(phase.kind);
    final progress = total.inMilliseconds == 0
        ? 0.0
        : 1 - phase.remaining.inMilliseconds / total.inMilliseconds;

    return Material(
      color: scheme.surfaceContainerHighest,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Text(
              phase.kind == BreakKind.micro ? 'Eye break' : 'Movement break',
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              exercise?.name ?? 'Take a breather',
              style: textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceLg),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 6,
                    color: scheme.primary,
                    backgroundColor: scheme.outlineVariant,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                if (exercise != null)
                  ExerciseFigure(art: exercise.art, size: 200),
              ],
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              formatCountdown(phase.remaining),
              style: textTheme.headlineMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            if (exercise != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    for (final (i, step) in exercise.steps.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTokens.spaceXs,
                        ),
                        child: Text(
                          '${i + 1}.  $step',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (exercise != null)
                    TextButton(
                      onPressed: () => ref
                          .read(breakSessionProvider.notifier)
                          .optOutCurrent(),
                      child: const Text("Can't do this exercise"),
                    ),
                  const SizedBox(width: AppTokens.spaceLg),
                  HoldToSkip(onConfirmed: engine.escape),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
