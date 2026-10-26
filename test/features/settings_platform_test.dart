// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/features/settings/settings_screen.dart';
import 'package:restifeye/platform/fake/fake_signals.dart';
import 'package:restifeye/platform/interfaces/tray_support.dart';
import 'package:restifeye/platform/windows/windows_tray_support.dart';
import 'package:restifeye/services/exercise_picker.dart';
import 'package:restifeye/services/providers.dart';

import '../helpers/overrides.dart';

class _GnomeTray implements TrayHostSupport {
  @override
  Future<TraySupport> check() async => const TraySupport(TrayState.working);

  @override
  Future<TraySupport> enable() => check();
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    TestHarness h, {
    required TrayHostSupport tray,
    required bool updates,
    Future<bool> Function(Uri)? openLink,
  }) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(h.db),
          engineServiceProvider.overrideWithValue(h.service),
          overlayControllerProvider.overrideWithValue(h.overlay),
          seedConfigProvider.overrideWithValue(h.engine.config),
          exercisePickerProvider.overrideWithValue(
            ExercisePicker(random: Random(7)),
          ),
          autostartProvider.overrideWithValue(FakeAutostart()),
          appLifecycleProvider.overrideWithValue(h.lifecycle),
          soundPlayerProvider.overrideWithValue(h.sounds),
          trayHostSupportProvider.overrideWithValue(tray),
          updateCheckAvailableProvider.overrideWithValue(updates),
          if (openLink != null) linkOpenerProvider.overrideWithValue(openLink),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Linux keeps its tray wording and the update switch', (
    tester,
  ) async {
    final h = TestHarness();
    await pump(tester, h, tray: _GnomeTray(), updates: true);

    expect(find.text('Showing in the top bar'), findsOneWidget);
    expect(find.text('Check for updates weekly'), findsOneWidget);
    await cleanupHarness(tester, h);
  });

  testWidgets('Windows names the taskbar corner and has no update switch', (
    tester,
  ) async {
    final h = TestHarness();
    await pump(tester, h, tray: const WindowsTraySupport(), updates: false);

    expect(find.text('Showing in the taskbar corner'), findsOneWidget);
    expect(find.text('Check for updates weekly'), findsNothing);
    await cleanupHarness(tester, h);
  });

  testWidgets('About credits XernAI and opens xernaitech.com', (tester) async {
    final h = TestHarness();
    final opened = <Uri>[];
    await pump(
      tester,
      h,
      tray: const WindowsTraySupport(),
      updates: false,
      openLink: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    expect(find.text('Made by XernAI'), findsOneWidget);
    await tester.tap(find.text('More apps at xernaitech.com'));
    expect(opened, [Uri.parse('https://xernaitech.com')]);
    await cleanupHarness(tester, h);
  });
}
