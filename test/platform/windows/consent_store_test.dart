// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/platform/fake/fake_registry.dart';
import 'package:restifeye/platform/interfaces/app_log.dart';
import 'package:restifeye/platform/windows/consent_store.dart';
import 'package:restifeye/platform/windows/user_registry.dart';
import 'package:restifeye/platform/windows/windows_context_signals.dart';

const _mic = '$consentStorePath\\microphone';
const _cam = '$consentStorePath\\webcam';

void _use(FakeUserRegistry r, String path, {int? start, int? stop}) {
  r.set(path, 'Value', 'Allow');
  if (start != null) r.set(path, 'LastUsedTimeStart', start);
  if (stop != null) r.set(path, 'LastUsedTimeStop', stop);
}

class _RecordingLog implements AppLog {
  final lines = <String>[];

  @override
  bool get enabled => true;

  @override
  void info(String message) => lines.add('INFO $message');

  @override
  void failure(String adapter, Object error) => lines.add('FAIL $adapter');

  @override
  void error(Object error, StackTrace? stack) => lines.add('ERROR');
}

class _BrokenRegistry implements UserRegistry {
  @override
  List<String> subkeys(String path) => throw StateError('access denied');

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test(
    'a stop of 0 after a start is in use; finished or never used is not',
    () {
      expect(const CaptureUse(app: 'a', start: 5, stop: 0).inUse, isTrue);
      expect(const CaptureUse(app: 'a', start: 5, stop: 9).inUse, isFalse);
      expect(const CaptureUse(app: 'a', start: 0, stop: 0).inUse, isFalse);
      expect(const CaptureUse(app: 'a').inUse, isFalse);
      expect(const CaptureUse(app: 'a', start: 5).inUse, isFalse);
    },
  );

  test('reads Store apps and desktop programs under both devices', () {
    final r = FakeUserRegistry();
    _use(
      r,
      '$_mic\\Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe',
      start: 1,
      stop: 2,
    );
    _use(
      r,
      '$_mic\\NonPackaged\\C:#Program Files#Zoom#bin#Zoom.exe',
      start: 3,
      stop: 4,
    );
    _use(
      r,
      '$_cam\\NonPackaged\\C:#Users#me#AppData#Teams#ms-teams.exe',
      start: 7,
      stop: 0,
    );

    final uses = readConsentStore(r);
    expect(uses.map((u) => u.app), {
      'Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe',
      'C:#Program Files#Zoom#bin#Zoom.exe',
      'C:#Users#me#AppData#Teams#ms-teams.exe',
    });
    expect(captureInUse(uses), 'C:#Users#me#AppData#Teams#ms-teams.exe');
  });

  test('a fresh account with no consent store is simply not busy', () async {
    final signals = WindowsContextSignals(
      registry: FakeUserRegistry(),
      log: const NoAppLog(),
    );
    expect(await signals.isBusy(), isFalse);
  });

  test('busy follows the device, and the log notes changes once', () async {
    final r = FakeUserRegistry();
    final log = _RecordingLog();
    final signals = WindowsContextSignals(registry: r, log: log);
    _use(r, '$_mic\\NonPackaged\\zoom.exe', start: 1, stop: 0);

    expect(await signals.isBusy(), isTrue);
    expect(await signals.isBusy(), isTrue);
    r.set('$_mic\\NonPackaged\\zoom.exe', 'LastUsedTimeStop', 2);
    expect(await signals.isBusy(), isFalse);

    expect(log.lines, [
      'INFO mic/camera in use by zoom.exe',
      'INFO mic/camera free',
    ]);
  });

  test('a registry failure fails open and is logged once', () async {
    final log = _RecordingLog();
    final signals = WindowsContextSignals(
      registry: _BrokenRegistry(),
      log: log,
    );
    expect(await signals.isBusy(), isFalse);
    expect(await signals.isBusy(), isFalse);
    expect(log.lines, ['FAIL meeting']);
    expect(() => signals.probe(), throwsStateError);
  });

  test('binary data in the fake is typed', () {
    final r = FakeUserRegistry()..set('k', 'b', Uint8List.fromList([1]));
    expect(r.readBinary('K', 'b'), [1]);
    expect(r.readString('k', 'b'), isNull);
  });
}
