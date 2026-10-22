// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/interfaces/app_log.dart';
import 'package:restifeye/platform/windows/windows_runner.dart';
import 'package:restifeye/platform/windows/windows_window_ops.dart';

class _Log implements AppLog {
  final lines = <String>[];

  @override
  bool get enabled => true;

  @override
  void info(String message) => lines.add(message);

  @override
  void failure(String adapter, Object error) =>
      lines.add('FAIL $adapter: $error');

  @override
  void error(Object error, StackTrace? stack) => lines.add('ERROR');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<String, Object?> runnerReplies;
  late bool windowManagerFocused;
  late List<String> windowManagerCalls;
  late _Log log;
  late WindowsWindowOps ops;

  setUp(() {
    runnerReplies = {
      'showWindow': true,
      'setFullScreen': true,
      'coversScreen': false,
      'forceForeground': true,
    };
    windowManagerFocused = false;
    windowManagerCalls = [];
    messenger
      ..setMockMethodCallHandler(
        const MethodChannel(WindowsRunner.channelName),
        (call) async => runnerReplies[call.method],
      )
      ..setMockMethodCallHandler(const MethodChannel('window_manager'), (
        call,
      ) async {
        windowManagerCalls.add(call.method);
        return call.method == 'isFocused' ? windowManagerFocused : null;
      });
    log = _Log();
    ops = WindowsWindowOps(WindowsRunner(), log);
  });

  test(
    'show is the runner\'s synchronous show, not window_manager\'s',
    () async {
      await ops.show();
      expect(windowManagerCalls, isNot(contains('show')));
      expect(log.lines, ['window show']);
    },
  );

  test('a window Windows did not show is a logged failure', () async {
    runnerReplies['showWindow'] = false;
    await expectLater(ops.show(), throwsStateError);
    expect(log.lines.single, startsWith('FAIL window: show'));
  });

  test('full screen goes through the runner both ways', () async {
    await ops.setFullScreen(true);
    await ops.setFullScreen(false);
    expect(windowManagerCalls, isNot(contains('setFullScreen')));
    expect(log.lines, ['window full screen on', 'window full screen off']);
  });

  test(
    'a covered screen counts as attending; an uncovered one does not',
    () async {
      expect(await ops.isFocused(), isFalse);

      runnerReplies['coversScreen'] = true;
      expect(await ops.isFocused(), isTrue, reason: 'Alt+Tab under the break');

      runnerReplies['coversScreen'] = false;
      windowManagerFocused = true;
      expect(await ops.isFocused(), isTrue);
    },
  );

  test('focus says whether Windows handed it over', () async {
    await ops.focus();
    runnerReplies['forceForeground'] = false;
    await ops.focus();
    expect(log.lines, [
      'window focus taken',
      'window focus refused by Windows',
    ]);
    expect(windowManagerCalls, ['focus']);
  });

  test('never waits on the renderer before hiding', () {
    expect(ops.isRendering, isFalse);
  });
}
