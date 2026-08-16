// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/startup_failure.dart';

void main() {
  testWidgets('names the failure and the database it could not open', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupFailureApp(
        error: Exception('duplicate column name: watch_seconds'),
        stack: StackTrace.current,
      ),
    );

    expect(find.text('RestifEye could not start'), findsOneWidget);
    expect(
      find.textContaining('duplicate column name: watch_seconds'),
      findsOneWidget,
    );
    expect(find.textContaining('RestifEye.db'), findsOneWidget);
    expect(find.textContaining('No data has been deleted'), findsOneWidget);
  });

  testWidgets('copies a report carrying the error and the database path', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      StartupFailureApp(
        error: Exception('database is locked'),
        stack: StackTrace.current,
      ),
    );
    await tester.tap(find.text('Copy details'));
    await tester.pump();

    expect(copied, contains('database is locked'));
    expect(copied, contains('RestifEye.db'));
  });

  testWidgets('renders without overflow on a small window', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      StartupFailureApp(error: Exception('boom'), stack: StackTrace.current),
    );

    expect(tester.takeException(), isNull);
  });
}
