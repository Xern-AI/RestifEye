// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../features/breaks/break_overlay.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../services/break_session.dart';
import '../services/overlay_reconciler.dart';
import '../services/providers.dart';
import 'shell.dart';
import 'theme.dart';

class RestifEyeApp extends StatelessWidget {
  const RestifEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RestifEye',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _Root(),
    );
  }
}

/// Root gate: onboarding on first run, then the shell with the break
/// overlay stacked on top whenever a break is active.
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Both must stay alive from app start: they react to the engine even
    // while the window sits hidden in the background.
    ref.watch(breakSessionProvider);
    ref.watch(overlayReconcilerProvider);

    final onboarded = ref.watch(onboardingDoneProvider);
    if (onboarded.value == false) {
      return const OnboardingScreen();
    }

    final phase = ref.watch(enginePhaseProvider).value;
    return _EscapeHatches(
      inBreak: phase is InBreak,
      child: Stack(
        children: [
          const AppShell(),
          if (phase case final InBreak inBreak) BreakOverlay(phase: inBreak),
        ],
      ),
    );
  }
}

/// Always-available ways out of the app.
///
/// An app that can take over the entire screen must never be able to trap
/// the user in it — that is not a theoretical concern here, it happened.
/// These work regardless of what the window, the engine or the compositor
/// think is going on:
///   * Esc — drop out of full-screen when no break is on
///   * Ctrl+Q — quit, from anywhere, always
///
/// Esc is deliberately inert during a break: leaving one is what the logged
/// 3-second hold-to-skip is for, and a stray Esc must not defeat it.
class _EscapeHatches extends ConsumerWidget {
  const _EscapeHatches({required this.inBreak, required this.child});

  final bool inBreak;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (inBreak) return;
          unawaited(ref.read(overlayControllerProvider).forceRestore());
        },
        const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () =>
            unawaited(ref.read(appLifecycleProvider).quit()),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
