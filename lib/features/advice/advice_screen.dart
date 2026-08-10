// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/providers.dart';

/// Data-driven habit advice from the rule engine.
class AdviceScreen extends ConsumerWidget {
  const AdviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final advice = ref.watch(adviceProvider).value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          children: [
            Text('Advice', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Based only on your own patterns. Computed on this device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            for (final item in advice)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
                child: Card(
                  color: item.positive
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceLg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.positive
                              ? Icons.celebration_outlined
                              : Icons.tips_and_updates_outlined,
                          color: item.positive
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppTokens.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppTokens.spaceXs),
                              Text(
                                item.body,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
