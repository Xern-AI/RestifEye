import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Today at a glance: next break countdown, screen time, streak.
/// Live values are wired to the break engine in M1; this shell renders the
/// layout with empty states until then.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Row(
              children: [
                Expanded(
                  child: _StatCard(label: 'Screen time', value: '—'),
                ),
                SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: _StatCard(label: 'Breaks taken', value: '—'),
                ),
                SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: _StatCard(label: 'Streak', value: '—'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextBreakCard extends StatelessWidget {
  const _NextBreakCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                    'Next break',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Engine not running yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
