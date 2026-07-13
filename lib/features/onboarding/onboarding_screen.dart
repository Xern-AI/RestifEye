import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/settings_repository.dart';
import '../../services/providers.dart';

/// Three honest screens: the promise, how strict mode works, work hours.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.spa_outlined,
      title: 'Breaks that respect your flow',
      body:
          'BreakTime reminds you to rest your eyes and move — but never '
          'mid-meeting, and never without a 30-second heads-up.\n\n'
          'Step away on your own and it counts your break automatically.',
    ),
    (
      icon: Icons.timer_outlined,
      title: 'Strict, but fair',
      body:
          'You can snooze a break a few times. When the budget runs out, '
          'the break happens.\n\n'
          'A real emergency? Hold the escape button for three seconds — '
          "it's always available, and it goes on your stats.",
    ),
    (
      icon: Icons.schedule_outlined,
      title: 'Only when you work',
      body:
          'Set your work hours and days in Settings and BreakTime stays '
          'silent the rest of the time.\n\n'
          'BreakTime starts with your computer and lives in the tray, so '
          'protecting your eyes never depends on remembering to launch it '
          '(you can turn autostart off in Settings).\n\n'
          'All data stays on this computer. No accounts, no cloud.',
    ),
  ];

  Future<void> _finish() async {
    await ref
        .read(settingsRepositoryProvider)
        .setFlag(SettingsRepository.flagOnboardingDone, true);
    ref.invalidate(onboardingDoneProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final page in _pages)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.spaceXl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(page.icon, size: 72, color: scheme.primary),
                              const SizedBox(height: AppTokens.spaceLg),
                              Text(
                                page.title,
                                style: textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppTokens.spaceMd),
                              Text(
                                page.body,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLg),
              child: Row(
                children: [
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                  const Spacer(),
                  for (var i = 0; i < _pages.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: CircleAvatar(
                        radius: 4,
                        backgroundColor: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                    child: Text(isLast ? 'Get started' : 'Next'),
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
