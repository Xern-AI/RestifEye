import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/break_config.dart';
import '../../services/providers.dart';

/// All break configuration. Every change applies immediately (engine
/// timers restart) and persists to disk.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(breakConfigProvider);
    final notifier = ref.read(breakConfigProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const _SectionHeader('Eye breaks'),
            _DurationTile(
              title: 'Interval',
              value: config.microInterval,
              min: const Duration(minutes: 10),
              max: const Duration(minutes: 60),
              step: const Duration(minutes: 5),
              onChanged: (d) =>
                  notifier.update(config.copyWith(microInterval: d)),
            ),
            _DurationTile(
              title: 'Length',
              value: config.microDuration,
              min: const Duration(seconds: 20),
              max: const Duration(seconds: 60),
              step: const Duration(seconds: 10),
              onChanged: (d) =>
                  notifier.update(config.copyWith(microDuration: d)),
            ),
            const _SectionHeader('Long breaks'),
            _DurationTile(
              title: 'Interval',
              value: config.longInterval,
              min: const Duration(minutes: 30),
              max: const Duration(minutes: 120),
              step: const Duration(minutes: 10),
              onChanged: (d) =>
                  notifier.update(config.copyWith(longInterval: d)),
            ),
            _DurationTile(
              title: 'Length',
              value: config.longDuration,
              min: const Duration(minutes: 3),
              max: const Duration(minutes: 15),
              step: const Duration(minutes: 1),
              onChanged: (d) =>
                  notifier.update(config.copyWith(longDuration: d)),
            ),
            const _SectionHeader('Snoozing'),
            ListTile(
              leading: const Icon(Icons.snooze_outlined),
              title: const Text('Snoozes per break'),
              subtitle: Text(
                config.snoozeBudget == 0
                    ? 'None — every break is strict'
                    : '${config.snoozeBudget} × '
                          '${config.snoozeLength.inMinutes} min',
              ),
              trailing: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 5, label: Text('5')),
                ],
                selected: {config.snoozeBudget},
                onSelectionChanged: (selection) => notifier.update(
                  config.copyWith(snoozeBudget: selection.first),
                ),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.lock_clock_outlined),
              title: const Text('Strict mode'),
              subtitle: const Text(
                'Once snoozes run out, the break takes the screen until done',
              ),
              value: config.strictMode,
              onChanged: (v) => notifier.update(config.copyWith(strictMode: v)),
            ),
            const _SectionHeader('Work hours'),
            _WorkHoursTile(config: config, onChanged: notifier.update),
            _WorkDaysTile(config: config, onChanged: notifier.update),
            const _SectionHeader('General'),
            SwitchListTile(
              secondary: const Icon(Icons.pause_circle_outlined),
              title: const Text('Pause BreakTime'),
              subtitle: const Text('No breaks until you resume'),
              value: ref.watch(pausedProvider),
              onChanged: (v) => ref.read(pausedProvider.notifier).set(v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.rocket_launch_outlined),
              title: const Text('Start at login'),
              value:
                  ref.watch(generalSettingsProvider).value?.autostart ?? false,
              onChanged: (v) =>
                  ref.read(generalSettingsProvider.notifier).setAutostart(v),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.system_update_alt_outlined),
              title: const Text('Check for updates weekly'),
              subtitle: const Text(
                'The only network request BreakTime ever makes',
              ),
              value:
                  ref.watch(generalSettingsProvider).value?.updateCheck ?? true,
              onChanged: (v) =>
                  ref.read(generalSettingsProvider.notifier).setUpdateCheck(v),
            ),
            const _SectionHeader('About'),
            const AboutListTile(
              icon: Icon(Icons.info_outlined),
              applicationName: 'BreakTime',
              applicationLegalese: '© 2026 Xernai · GPL-3.0',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Slider over a duration range with step increments.
class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String title;
  final Duration value;
  final Duration min;
  final Duration max;
  final Duration step;
  final ValueChanged<Duration> onChanged;

  String _label(Duration d) =>
      d.inMinutes >= 1 ? '${d.inMinutes} min' : '${d.inSeconds} s';

  @override
  Widget build(BuildContext context) {
    final divisions = (max - min).inSeconds ~/ step.inSeconds;
    final clamped = value < min
        ? min
        : value > max
        ? max
        : value;
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(title)),
          Text(_label(clamped), style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
      subtitle: Slider(
        value: clamped.inSeconds.toDouble(),
        min: min.inSeconds.toDouble(),
        max: max.inSeconds.toDouble(),
        divisions: divisions,
        onChanged: (seconds) => onChanged(Duration(seconds: seconds.round())),
      ),
    );
  }
}

class _WorkHoursTile extends StatelessWidget {
  const _WorkHoursTile({required this.config, required this.onChanged});

  final BreakConfig config;
  final ValueChanged<BreakConfig> onChanged;

  String _fmt(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final initial = start ? config.workStartMinutes : config.workEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    onChanged(
      start
          ? config.copyWith(workStartMinutes: minutes)
          : config.copyWith(workEndMinutes: minutes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDay =
        config.workStartMinutes == 0 && config.workEndMinutes == 24 * 60;
    return ListTile(
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('Active window'),
      subtitle: Text(
        allDay
            ? 'All day'
            : '${_fmt(config.workStartMinutes)} – '
                  '${_fmt(config.workEndMinutes)}',
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => _pick(context, start: true),
            child: Text('From ${_fmt(config.workStartMinutes)}'),
          ),
          OutlinedButton(
            onPressed: () => _pick(context, start: false),
            child: Text(
              'To ${_fmt(config.workEndMinutes == 1440 ? 0 : config.workEndMinutes)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkDaysTile extends StatelessWidget {
  const _WorkDaysTile({required this.config, required this.onChanged});

  final BreakConfig config;
  final ValueChanged<BreakConfig> onChanged;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (var day = 1; day <= 7; day++)
            FilterChip(
              label: Text(_labels[day - 1]),
              selected: config.workDays.contains(day),
              onSelected: (selected) {
                final days = {...config.workDays};
                selected ? days.add(day) : days.remove(day);
                if (days.isEmpty) return; // at least one active day
                onChanged(config.copyWith(workDays: days));
              },
            ),
        ],
      ),
    );
  }
}
