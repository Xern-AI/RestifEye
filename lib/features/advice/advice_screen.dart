// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/advice_engine.dart';
import '../../services/providers.dart';

/// Data-driven habit advice from the rule engine.
///
/// Split into what is going well and what is worth changing, in that order.
/// A page that opens with a list of failings gets closed; the same page
/// opening with something earned gets read.
class AdviceScreen extends ConsumerWidget {
  const AdviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final advice = ref.watch(adviceProvider).value ?? const [];
    final praise = advice.where((a) => a.positive).toList();
    final suggestions = advice.where((a) => !a.positive).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLg),
          children: [
            Text('Advice', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              'Based only on your own patterns, over the last four weeks. '
              'Computed on this device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            if (praise.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.celebration_outlined,
                label: 'Going well',
              ),
              for (final item in praise) _AdviceCard(item: item),
              const SizedBox(height: AppTokens.spaceMd),
            ],
            if (suggestions.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.tips_and_updates_outlined,
                label: 'Worth changing',
              ),
              for (final item in suggestions) _AdviceCard(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppTokens.spaceSm),
          Text(label, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.item});

  final Advice item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
                    ? Icons.check_circle_outline
                    : Icons.lightbulb_outline,
                color: item.positive
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTokens.spaceXs),
                    Text(item.body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
