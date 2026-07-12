import 'package:flutter/material.dart';

/// App settings. Real, persisted settings arrive with the data layer in M1;
/// the full option set (intervals, snooze budget, work hours) lands in M2.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const ListTile(
              leading: Icon(Icons.timer_outlined),
              title: Text('Break intervals'),
              subtitle: Text('Available once the break engine lands'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.snooze_outlined),
              title: Text('Snooze budget'),
              subtitle: Text('Available once the break engine lands'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.schedule_outlined),
              title: Text('Work & quiet hours'),
              subtitle: Text('Available once the break engine lands'),
              enabled: false,
            ),
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
