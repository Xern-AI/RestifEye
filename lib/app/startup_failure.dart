// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import 'theme.dart';
import 'version.dart';

/// Shown when [bootstrap] throws. The GTK window is created by the runner
/// before Dart runs, so a crash during startup otherwise leaves an empty
/// black window on screen with nothing to act on and nothing to report.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    required this.error,
    required this.stack,
    super.key,
  });

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestifEye',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: _StartupFailureScreen(error: error, stack: stack),
    );
  }
}

class _StartupFailureScreen extends StatelessWidget {
  const _StartupFailureScreen({required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  String get _versionLine =>
      appBuild == null ? appVersion : '$appVersion+${appBuild!}';

  String get _report =>
      'RestifEye $_versionLine\n'
      'Database: ${AppDatabase.productionPath}\n\n'
      '$error\n\n$stack';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'RestifEye could not start',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your break tracking is paused until this is resolved. '
                  'No data has been deleted.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _Field(label: 'Version', value: _versionLine),
                _Field(label: 'Database', value: AppDatabase.productionPath),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      '$error',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: _report)),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy details'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste these into a GitHub issue at '
                        'github.com/Xern-AI/restifeye',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
