import 'package:flutter/material.dart';

/// Data-driven habit advice. The rule-based advice engine arrives in M3.
class AdviceScreen extends StatelessWidget {
  const AdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Advice', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Personalized suggestions based on your own patterns\n'
              'will appear here after your first week.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
