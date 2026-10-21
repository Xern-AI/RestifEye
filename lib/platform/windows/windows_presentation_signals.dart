// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';

import '../interfaces/app_log.dart';
import '../interfaces/presentation_signals.dart';

/// "Don't interrupt me" from `SHQueryUserNotificationState`, the same answer
/// Windows uses to decide whether its own notifications may pop up.
///
/// It covers full-screen apps (including browser video in full screen),
/// Direct3D full-screen games and presentation mode. Video playing in a
/// normal window is a known gap: Windows reports nothing for it, and guessing
/// from audio would let a background playlist hold breaks all day — the same
/// reason the Linux adapter keys off idle inhibitors rather than sound.
class WindowsPresentationSignals implements PresentationSignals {
  WindowsPresentationSignals({required this.log});

  final AppLog log;
  bool _reported = false;

  static final _query = DynamicLibrary.open('shell32.dll')
      .lookupFunction<
        Int32 Function(Pointer<Int32>),
        int Function(Pointer<Int32>)
      >('SHQueryUserNotificationState');

  /// Throws when Windows cannot answer, so startup can log it.
  void probe() => _state();

  @override
  Future<PresentationState> sample() async {
    try {
      final state = _state();
      if (!quietStates.contains(state)) return PresentationState.idle;
      final owner = _foregroundProcess();
      return presentationFrom(
        state: state,
        foregroundIsOurs: owner.pid == pid,
        foregroundApp: owner.app,
      );
    } on Object catch (e) {
      if (!_reported) log.failure('presentation', e);
      _reported = true;
      return PresentationState.idle;
    }
  }

  int _state() => using((arena) {
    final out = arena<Int32>();
    final hr = _query(out);
    if (hr != 0) throw StateError('SHQueryUserNotificationState hr=$hr');
    return out.value;
  });

  ({int pid, String? app}) _foregroundProcess() => using((arena) {
    final processId = arena<Uint32>();
    GetWindowThreadProcessId(GetForegroundWindow(), processId);
    final id = processId.value;
    final opened = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, id);
    if (!opened.value.isValid) return (pid: id, app: null);
    final handle = opened.value;
    try {
      final size = arena<Uint32>()..value = MAX_PATH;
      final name = PWSTR(arena<Uint16>(MAX_PATH).cast());
      final ok = QueryFullProcessImageName(
        handle,
        PROCESS_NAME_WIN32,
        name,
        size,
      );
      if (!ok.value) return (pid: id, app: null);
      return (
        pid: id,
        app: p.windows.basenameWithoutExtension(
          name.toDartString(length: size.value),
        ),
      );
    } finally {
      CloseHandle(handle);
    }
  });
}

/// `QUNS_BUSY` (a full-screen app), `QUNS_RUNNING_D3D_FULL_SCREEN` and
/// `QUNS_PRESENTATION_MODE`. Locked screens, quiet hours after setup and
/// "accepts notifications" are not something on screen to protect.
const quietStates = {2, 3, 4};

/// Maps the query result to a pause, ignoring our own break window: a
/// full-screen break would otherwise report itself as a film and pause the
/// very break it is showing.
PresentationState presentationFrom({
  required int state,
  required bool foregroundIsOurs,
  String? foregroundApp,
}) {
  if (!quietStates.contains(state) || foregroundIsOurs) {
    return PresentationState.idle;
  }
  final app = foregroundApp?.trim();
  return PresentationState(
    active: true,
    byApp: app == null || app.isEmpty ? null : app,
  );
}
