// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/interfaces/app_log.dart';
import 'package:restifeye/platform/interfaces/presentation_signals.dart';
import 'package:restifeye/platform/interfaces/sound_player.dart';
import 'package:restifeye/platform/windows/windows_idle_monitor.dart';
import 'package:restifeye/platform/windows/windows_presentation_signals.dart';
import 'package:restifeye/platform/windows/windows_runner.dart';
import 'package:restifeye/platform/windows/windows_session_signals.dart';
import 'package:restifeye/platform/windows/windows_sound_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('idle from ticks', () {
    test('is the plain difference between the two ticks', () {
      expect(
        idleFromTicks(now: 125000, lastInput: 5000),
        const Duration(seconds: 120),
      );
      expect(idleFromTicks(now: 7, lastInput: 7), Duration.zero);
    });

    test('survives the 49.7-day wrap of the 32-bit tick counter', () {
      expect(
        idleFromTicks(now: 1000, lastInput: 0xFFFFFFFF - 999),
        const Duration(milliseconds: 2000),
      );
    });
  });

  group('session away state', () {
    test('away is lock or sleep, and wake while locked is still away', () {
      final state = SessionAwayState();
      expect(state.apply('lock'), isTrue);
      expect(state.apply('suspend'), isTrue);
      expect(state.apply('resume'), isTrue, reason: 'woke up on the lock');
      expect(state.apply('unlock'), isFalse);
    });

    test('sleep without a lock, and unknown events change nothing', () {
      final state = SessionAwayState();
      expect(state.apply('suspend'), isTrue);
      expect(state.apply('display-off'), isTrue);
      expect(state.apply('resume'), isFalse);
      expect(state.apply('unlock'), isFalse);
    });
  });

  group('runner channel', () {
    const codec = StandardMethodCodec();

    Future<void> fromRunner(String method, [Object? args]) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            WindowsRunner.channelName,
            codec.encodeMethodCall(MethodCall(method, args)),
            (_) {},
          );
    }

    test('session events from the window procedure become away/back', () async {
      final runner = WindowsRunner();
      final signals = WindowsSessionSignals(runner);
      final seen = <bool>[];
      final sub = signals.away.listen(seen.add);

      await fromRunner('session', 'lock');
      await fromRunner('session', 'unlock');
      await fromRunner('relaunch');
      await pumpEventQueue();

      expect(seen, [true, false]);
      await sub.cancel();
      await signals.dispose();
    });

    test('a relaunch message reaches the relaunch stream', () async {
      final runner = WindowsRunner();
      final relaunches = <void>[];
      final sub = runner.relaunches.listen(relaunches.add);
      await fromRunner('relaunch');
      await pumpEventQueue();
      expect(relaunches, hasLength(1));
      await sub.cancel();
    });
  });

  group('presentation', () {
    test('full screen, D3D full screen and presentation mode pause', () {
      for (final state in [2, 3, 4]) {
        expect(
          presentationFrom(
            state: state,
            foregroundIsOurs: false,
            foregroundApp: 'chrome',
          ),
          const PresentationState(active: true, byApp: 'chrome'),
        );
      }
    });

    test('everything else does not', () {
      for (final state in [1, 5, 6, 7]) {
        expect(
          presentationFrom(state: state, foregroundIsOurs: false),
          PresentationState.idle,
        );
      }
    });

    test('our own full-screen break never pauses itself', () {
      expect(
        presentationFrom(state: 2, foregroundIsOurs: true, foregroundApp: 'x'),
        PresentationState.idle,
      );
    });

    test('an unnamed app still pauses, without a name', () {
      expect(
        presentationFrom(state: 3, foregroundIsOurs: false, foregroundApp: ' '),
        const PresentationState(active: true),
      );
    });
  });

  group('sound', () {
    test('every app sound maps to a distinct Windows scheme event', () {
      final aliases = AppSound.values.map(soundAlias).toSet();
      expect(aliases, hasLength(AppSound.values.length));
    });

    test('disabled plays nothing and never throws', () async {
      final player = WindowsSoundPlayer(log: const NoAppLog(), enabled: false);
      await expectLater(player.play(AppSound.warning), completes);
    });
  });
}
