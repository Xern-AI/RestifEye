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
        foregroundCoversMonitor: _foregroundCoversMonitor(),
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

  bool _foregroundCoversMonitor() => using((arena) {
    final window = GetForegroundWindow();
    final rect = arena<RECT>();
    if (!GetWindowRect(window, rect).value) return false;
    final monitor = arena<MONITORINFO>()..ref.cbSize = sizeOf<MONITORINFO>();
    final handle = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
    if (!GetMonitorInfo(handle, monitor)) return false;
    final w = rect.ref;
    final m = monitor.ref.rcMonitor;
    return coversMonitor(
      window: (left: w.left, top: w.top, right: w.right, bottom: w.bottom),
      monitor: (left: m.left, top: m.top, right: m.right, bottom: m.bottom),
    );
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

/// `QUNS_PRESENTATION_MODE` is a Windows setting rather than a window, so it
/// needs no full-screen window in front to count.
const _presentationMode = 4;

/// Maps the query result to a pause.
///
/// Ignores our own break window, which would otherwise report itself as a
/// film and pause the very break it is showing. And for the full-screen
/// states it also requires the app in front to actually cover its monitor:
/// Windows' answer lags a second or two behind a window leaving full screen,
/// and the first Windows test logged "paused media by Notepad" just after
/// every full-screen break, when the lagging answer met whatever app got the
/// focus back.
PresentationState presentationFrom({
  required int state,
  required bool foregroundIsOurs,
  required bool foregroundCoversMonitor,
  String? foregroundApp,
}) {
  if (!quietStates.contains(state) || foregroundIsOurs) {
    return PresentationState.idle;
  }
  if (state != _presentationMode && !foregroundCoversMonitor) {
    return PresentationState.idle;
  }
  final app = foregroundApp?.trim();
  return PresentationState(
    active: true,
    byApp: app == null || app.isEmpty ? null : app,
  );
}

typedef ScreenRect = ({int left, int top, int right, int bottom});

/// Whether [window] spans the whole of [monitor], as a full-screen video,
/// slide show or game does. A maximised window stops at the taskbar, so it
/// does not.
bool coversMonitor({required ScreenRect window, required ScreenRect monitor}) =>
    window.left <= monitor.left &&
    window.top <= monitor.top &&
    window.right >= monitor.right &&
    window.bottom >= monitor.bottom;
