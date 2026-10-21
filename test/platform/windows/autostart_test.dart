// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/fake/fake_registry.dart';
import 'package:restifeye/platform/windows/windows_autostart.dart';

const _exe = r'C:\Users\me\Downloads\RestifEye 0.2.0\restifeye.exe';
const _run = WindowsAutostart.runPath;
const _approved = WindowsAutostart.approvedPath;
const _name = WindowsAutostart.valueName;

Uint8List _approval(int first) =>
    Uint8List.fromList([first, ...List.filled(11, 0)]);

void main() {
  late FakeUserRegistry registry;
  late WindowsAutostart autostart;

  setUp(() {
    registry = FakeUserRegistry();
    autostart = WindowsAutostart(registry: registry, executable: _exe);
  });

  test('enable writes the quoted path; disable removes it', () async {
    expect(await autostart.isEnabled(), isFalse);

    await autostart.setEnabled(true);
    expect(registry.readString(_run, _name), '"$_exe"');
    expect(await autostart.isEnabled(), isTrue);

    await autostart.setEnabled(false);
    expect(registry.readString(_run, _name), isNull);
    expect(await autostart.isEnabled(), isFalse);
  });

  test('switched off in Task Manager reads as off', () async {
    await autostart.setEnabled(true);
    registry.set(_approved, _name, _approval(0x03));
    expect(await autostart.isEnabled(), isFalse);

    registry.set(_approved, _name, _approval(0x02));
    expect(await autostart.isEnabled(), isTrue);
  });

  test('enabling here clears a Task Manager "disabled" mark', () async {
    await autostart.setEnabled(true);
    registry.set(_approved, _name, _approval(0x03));

    await autostart.setEnabled(true);
    expect(registry.readBinary(_approved, _name), isNull);
    expect(await autostart.isEnabled(), isTrue);
  });

  test('StartupApproved: odd first byte is disabled, absent is not', () {
    expect(startupApprovedDisabled(null), isFalse);
    expect(startupApprovedDisabled(Uint8List(0)), isFalse);
    expect(startupApprovedDisabled(_approval(0x02)), isFalse);
    expect(startupApprovedDisabled(_approval(0x06)), isFalse);
    expect(startupApprovedDisabled(_approval(0x03)), isTrue);
    expect(startupApprovedDisabled(_approval(0x07)), isTrue);
  });

  group('repairPath', () {
    test(
      'points an enabled entry from an older unpacked copy at this one',
      () async {
        registry.set(_run, _name, r'"C:\old\restifeye.exe"');
        expect(await autostart.repairPath(), isTrue);
        expect(registry.readString(_run, _name), '"$_exe"');
        expect(await autostart.repairPath(), isFalse);
      },
    );

    test(
      'never turns autostart on, nor overrides a Task Manager opt-out',
      () async {
        expect(await autostart.repairPath(), isFalse);
        expect(registry.readString(_run, _name), isNull);

        registry
          ..set(_run, _name, r'"C:\old\restifeye.exe"')
          ..set(_approved, _name, _approval(0x03));
        expect(await autostart.repairPath(), isFalse);
        expect(registry.readString(_run, _name), r'"C:\old\restifeye.exe"');
      },
    );
  });
}
