// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/tray_face.dart';
import 'package:restifeye/core/mood/mood.dart';
import 'package:restifeye/platform/interfaces/app_log.dart';
import 'package:restifeye/platform/interfaces/tray_indicator.dart';
import 'package:restifeye/platform/windows/windows_runner.dart';
import 'package:restifeye/platform/windows/windows_tray.dart';

TrayPixmap _icon(int size) => TrayPixmap(
  width: size,
  height: size,
  argb32: List.filled(size * size * 4, 0),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pickPixmap', () {
    final icons = [_icon(32), _icon(16), _icon(24)];

    test('takes the exact size when offered', () {
      expect(pickPixmap(icons, 24).width, 24);
    });

    test('else the smallest larger one, else the largest', () {
      expect(pickPixmap(icons, 20).width, 24);
      expect(pickPixmap(icons, 64).width, 32);
    });
  });

  test('ARGB network order becomes BGRA, alpha untouched', () {
    expect(argbToBgra([0x80, 0x11, 0x22, 0x33, 0xFF, 1, 2, 3]), [
      0x33, 0x22, 0x11, 0x80, //
      3, 2, 1, 0xFF,
    ]);
  });

  group('tooltip', () {
    test('names the app above the status', () {
      expect(trayTooltip('Doing well'), 'RestifEye\nDoing well');
    });

    test('fits szTip and never splits a surrogate pair', () {
      final long = trayTooltip('x' * 300);
      expect(long.length, lessThanOrEqualTo(127));
      expect(long, endsWith('…'));

      final prefix = 'y' * (125 - 'RestifEye\n'.length);
      final clipped = trayTooltip('$prefix😀 and more');
      expect(clipped.length, lessThanOrEqualTo(127));
      final beforeEllipsis = clipped.codeUnitAt(clipped.length - 2);
      expect(beforeEllipsis >= 0xD800 && beforeEllipsis <= 0xDBFF, isFalse);
    });
  });

  test('every tray event maps to its action', () {
    expect(trayActionFor('open'), TrayAction.open);
    expect(trayActionFor('togglePause'), TrayAction.togglePause);
    expect(trayActionFor('quit'), TrayAction.quit);
    expect(trayActionFor('nonsense'), isNull);
  });

  test('the face is drawn at every Windows size, 16 px included', () async {
    final faces = await renderTrayFace(Mood.good, sizes: windowsTraySizes);
    expect(faces.map((f) => f.width), windowsTraySizes);
    for (final f in faces) {
      expect(f.argb32, hasLength(f.width * f.height * 4));
      expect(f.argb32.any((b) => b != 0), isTrue);
    }
  });

  test('sends the face that matches the DPI, and the menu labels', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(WindowsRunner.channelName),
          (call) async {
            calls.add(call);
            return switch (call.method) {
              'trayIconSize' => 20,
              'traySetIcon' => true,
              _ => null,
            };
          },
        );
    final tray = WindowsTrayIndicator(
      runner: WindowsRunner(),
      log: const NoAppLog(),
    );

    await tray.init(icons: [_icon(16), _icon(20), _icon(24)]);
    await tray.setPaused(true);

    final icon = calls.firstWhere((c) => c.method == 'traySetIcon');
    final args = icon.arguments as Map<Object?, Object?>;
    expect(args['size'], 20);
    expect((args['bgra'] as Uint8List).length, 20 * 20 * 4);
    final menus = calls.where((c) => c.method == 'traySetMenu').toList();
    expect((menus.first.arguments as Map)['pause'], 'Pause breaks');
    expect((menus.last.arguments as Map)['pause'], 'Resume breaks');

    await tray.dispose();
    expect(calls.last.method, 'trayRemove');
  });
}
