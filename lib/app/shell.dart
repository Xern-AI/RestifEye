// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../features/advice/advice_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';

/// Top-level navigation shell: rail on desktop widths, bar on narrow ones.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    (
      icon: Icons.space_dashboard_outlined,
      selected: Icons.space_dashboard,
      label: 'Dashboard',
    ),
    (
      icon: Icons.insights_outlined,
      selected: Icons.insights,
      label: 'Analytics',
    ),
    (
      icon: Icons.tips_and_updates_outlined,
      selected: Icons.tips_and_updates,
      label: 'Advice',
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const _screens = <Widget>[
    DashboardScreen(),
    AnalyticsScreen(),
    AdviceScreen(),
    SettingsScreen(),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 600;
        final body = IndexedStack(index: _selectedIndex, children: _screens);

        if (!useRail) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _select,
                extended: constraints.maxWidth >= 1000,
                labelType: constraints.maxWidth >= 1000
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selected),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}
