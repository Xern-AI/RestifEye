import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../features/breaks/break_overlay.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../services/break_session.dart';
import '../services/providers.dart';
import 'shell.dart';
import 'theme.dart';

class BreakTimeApp extends StatelessWidget {
  const BreakTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakTime',
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
    // Keep the break session alive from app start — it reacts to engine
    // events even while the window sits hidden in the background.
    ref.watch(breakSessionProvider);

    final onboarded = ref.watch(onboardingDoneProvider);
    if (onboarded.value == false) {
      return const OnboardingScreen();
    }

    final phase = ref.watch(enginePhaseProvider).value;
    return Stack(
      children: [
        const AppShell(),
        if (phase case final InBreak inBreak) BreakOverlay(phase: inBreak),
      ],
    );
  }
}
