// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/interfaces/overlay_controller.dart';
import 'package:restifeye/platform/linux/window_ops.dart';
import 'package:restifeye/platform/linux/window_takeover.dart';
import 'package:window_manager/window_manager.dart';

/// Records the order window calls land in — the only thing that has ever
/// gone wrong here.
class FakeWindowOps implements WindowOps {
  final List<String> calls = [];

  bool visible = false;

  /// Whether the renderer claims a frame is in flight. Unmapping the window
  /// while this is true is what killed the process on Wayland.
  @override
  bool isRendering = false;

  @override
  Future<void> prepare({
    required String title,
    required WindowListener on,
  }) async => calls.add('prepare');

  @override
  Future<void> show() async {
    visible = true;
    calls.add('show');
  }

  @override
  Future<void> hide() async {
    visible = false;
    calls.add('hide');
  }

  @override
  Future<void> focus() async => calls.add('focus');

  @override
  Future<void> setFullScreen(bool value) async =>
      calls.add('fullscreen:$value');

  @override
  Future<void> setAlwaysOnTop(bool value) async => calls.add('onTop:$value');

  @override
  Future<bool> isVisible() async => visible;

  @override
  Future<void> destroy() async => calls.add('destroy');
}

const _break = BreakWindowState(inBreak: true, strict: false, fullscreen: true);

void main() {
  late FakeWindowOps ops;
  late WindowTakeover takeover;

  setUp(() {
    ops = FakeWindowOps();
    takeover = WindowTakeover(ops: ops);
  });

  /// The 1 Hz re-assertion the reconciler drives, which is the only thing that
  /// services a pending hide.
  Future<void> tick([int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await takeover.apply(BreakWindowState.normal);
    }
  }

  /// Quiet ticks a break-end hide waits out before unmapping. Mirrors
  /// `WindowTakeover._postBreakSettleTicks`.
  const settleTicks = 3;

  group('restoring visibility after a break', () {
    test('a break started from the tray ends back in the tray', () async {
      await takeover.apply(_break);
      expect(ops.visible, isTrue, reason: 'a break has to show the window');

      await takeover.apply(BreakWindowState.normal);
      await tick(settleTicks);

      expect(ops.visible, isFalse);
    });

    test('a window the user had open is left open', () async {
      ops.visible = true;
      await takeover.apply(_break);
      await takeover.apply(BreakWindowState.normal);
      await tick(settleTicks);

      expect(ops.calls, isNot(contains('hide')));
      expect(ops.visible, isTrue);
    });
  });

  group('unmapping is deferred until the renderer is quiet', () {
    // The regression this whole gate exists for: hiding the window while the
    // toolkit still has a frame to draw destroys the surface underneath it
    // and takes the process down with SIGSEGV.
    test('a busy renderer postpones the hide instead of crashing', () async {
      await takeover.apply(_break);

      ops.isRendering = true; // the exercise illustration is still animating
      await takeover.apply(BreakWindowState.normal);

      expect(ops.calls, isNot(contains('hide')));
      expect(
        ops.calls,
        containsAll(<String>['onTop:false', 'fullscreen:false']),
        reason: 'presentation is dropped immediately; only the unmap waits',
      );
    });

    // `isRendering` reports a *framework* intention to build another frame.
    // The frame that killed the process was two stages downstream, already
    // handed to GTK, so an idle reading is not on its own proof of safety.
    // Hence the wait below is measured in ticks, not in one clean sample.
    test('the hide never lands on the tick that ended the break', () async {
      await takeover.apply(_break);

      ops.isRendering = false; // Dart is idle the instant the overlay pops
      await takeover.apply(BreakWindowState.normal);

      expect(
        ops.calls,
        isNot(contains('hide')),
        reason: 'the frame that ended the break is still inside GTK',
      );
    });

    test(
      'a quiet renderer performs the hide after the settle window',
      () async {
        await takeover.apply(_break);
        ops.isRendering = true;
        await takeover.apply(BreakWindowState.normal);

        ops.isRendering = false; // the break screen is gone, frames stop
        await tick(settleTicks - 1);
        expect(ops.calls, isNot(contains('hide')), reason: 'one tick short');

        await tick();

        expect(ops.visible, isFalse);
        expect(ops.calls.where((c) => c == 'hide'), hasLength(1));
      },
    );

    test('a busy tick restarts the settle window', () async {
      await takeover.apply(_break);
      await takeover.apply(BreakWindowState.normal);

      ops.isRendering = false;
      await tick(settleTicks - 1);

      ops.isRendering = true; // something started animating again
      await tick();
      ops.isRendering = false;
      await tick(settleTicks - 1);

      expect(
        ops.calls,
        isNot(contains('hide')),
        reason: 'quiet ticks are consecutive, not cumulative',
      );

      await tick();
      expect(ops.visible, isFalse);
    });

    test('a new break supersedes a hide that never happened', () async {
      await takeover.apply(_break);
      ops.isRendering = true;
      await takeover.apply(BreakWindowState.normal);

      ops.isRendering = false;
      await takeover.apply(_break); // next break arrives first
      await tick(settleTicks);

      expect(ops.visible, isTrue);
      expect(ops.calls, isNot(contains('hide')));
    });

    test('opening the window cancels a pending hide', () async {
      await takeover.apply(_break);
      ops.isRendering = true;
      await takeover.apply(BreakWindowState.normal);

      await takeover.presentWindow();
      ops.isRendering = false;
      await tick(settleTicks);

      expect(
        ops.visible,
        isTrue,
        reason: 'the window must not vanish out from under the user',
      );
    });

    // The close-to-tray path is deliberately exempt from the settle window:
    // an idle window has nothing in the pipeline, it has never crashed, and a
    // three-second lag between clicking X and the window going away would read
    // as the app being wedged.
    test('closing to the tray hides without waiting out the ticks', () async {
      takeover.onWindowClose();
      await tick();

      expect(ops.visible, isFalse);
      expect(ops.calls.where((c) => c == 'hide'), hasLength(1));
    });
  });

  test('forceRestore drops break presentation but never hides', () async {
    await takeover.apply(_break);

    await takeover.forceRestore();

    expect(ops.calls, isNot(contains('hide')));
    expect(ops.visible, isTrue, reason: 'the escape hatch leaves a window');
  });
}
