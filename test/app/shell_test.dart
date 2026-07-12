import 'package:breaktime/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/overrides.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(overrides: testOverrides, child: const BreakTimeApp()),
    );
    await tester.pump(); // let stream providers deliver their first values
  }

  group('AppShell navigation', () {
    testWidgets(
      'shows a navigation rail at desktop width and switches screens',
      (tester) async {
        await pumpApp(tester, const Size(1280, 800));

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        expect(find.text('Break intervals'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.insights_outlined));
        await tester.pumpAndSettle();
        expect(find.textContaining('trends will appear'), findsOneWidget);
      },
    );

    testWidgets('shows a bottom navigation bar at narrow width', (
      tester,
    ) async {
      await pumpApp(tester, const Size(500, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('all four destinations are present and labeled', (
      tester,
    ) async {
      await pumpApp(tester, const Size(1280, 800));

      for (final label in ['Dashboard', 'Analytics', 'Advice', 'Settings']) {
        expect(
          find.text(label),
          findsWidgets,
          reason: 'missing destination: $label',
        );
      }
    });
  });

  group('Dashboard live data', () {
    testWidgets('renders countdown and today stats from providers', (
      tester,
    ) async {
      await pumpApp(tester, const Size(1280, 800));

      expect(find.text('Next eye break'), findsOneWidget);
      expect(find.text('12:34'), findsOneWidget);
      expect(find.text('3h 20m'), findsOneWidget); // screen time
      expect(find.text('5'), findsOneWidget); // 4 completed + 1 credited
      expect(find.text('1h 20m'), findsOneWidget); // longest focus
    });
  });
}
