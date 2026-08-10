// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../app/tray_face.dart';
import '../core/mood/mood.dart';
import '../platform/interfaces/tray_indicator.dart';

/// Paints the current mood onto the tray icon.
///
/// Separate from `MoodService` on purpose: that decides *what* the app feels,
/// this decides how it looks. Only this half needs a rendering pipeline, so
/// only this half is hard to test.
class TrayMoodPresenter {
  TrayMoodPresenter({
    required this._tray,
    required this._moods,
    this.enabled = true,
    Mood initial = Mood.good,
  }) : _mood = initial;

  /// A short acknowledgement, not an idle animation.
  ///
  /// Every frame is a D-Bus signal plus the host re-reading two icon
  /// properties, so a continuous loop would be a genuine background cost for
  /// something nobody is looking at. Four frames on a change is enough to
  /// catch the eye, and a mood change is exactly when the eye should be
  /// caught. It is also the "your break is over" cue that replaced popping
  /// the window back up.
  static const _pulse = [1.0, 1.06, 0.97, 1.0];
  static const _frameGap = Duration(milliseconds: 220);

  final TrayIndicator _tray;
  final Stream<Mood> _moods;

  /// When off, the icon stays on the neutral brand face.
  bool enabled;

  StreamSubscription<Mood>? _sub;
  Timer? _demo;

  /// Serializes icon writes. Rendering a face is five images with an await
  /// apiece, so two updates in flight together used to interleave and finish
  /// in either order — leaving the tray showing whichever mood happened to
  /// render last rather than whichever mood is current.
  Future<void> _queue = Future.value();

  /// Seeded from the service rather than defaulting to cheerful: the mood is
  /// computed before a tray host is found, so starting at `good` would show a
  /// smile to someone the app had already concluded was skipping breaks.
  Mood _mood;

  /// Identifies the newest intent. Anything rendered for an older one is
  /// dropped rather than written, so a superseded pulse can never be the
  /// last thing the tray hears about.
  int _token = 0;

  Future<void> start() async {
    _sub = _moods.listen((mood) => unawaited(show(mood)));
    await refresh();
  }

  /// Renders [mood] and plays the acknowledgement pulse.
  Future<void> show(Mood mood) async {
    _mood = mood;
    if (!enabled) return refresh();

    final token = ++_token;
    for (final scale in _pulse) {
      if (token != _token) return; // superseded by a newer mood
      await _apply(mood, token, scale: scale);
      if (scale != _pulse.last) await Future<void>.delayed(_frameGap);
    }
  }

  /// Dev-only (`RESTIFEYE_DEV=1`): walks every mood on a short loop so the
  /// colours, faces and pulse can actually be watched.
  ///
  /// This exists because the feature is otherwise almost impossible to
  /// inspect: real moods move on the scale of hours, and the honest answer to
  /// "is the icon updating?" was previously to skip breaks for twenty minutes
  /// and hope. Not wired into release builds.
  void startDemo({Duration every = const Duration(seconds: 5)}) {
    var i = 0;
    _demo = Timer.periodic(every, (_) {
      unawaited(show(Mood.values[i++ % Mood.values.length]));
    });
  }

  /// Re-asserts the current mood — at startup, and when the setting is
  /// toggled. Supersedes any pulse still in flight: this is the newest word
  /// on what the icon should be.
  Future<void> refresh() => _apply(enabled ? _mood : Mood.good, ++_token);

  Future<void> _apply(Mood mood, int token, {double scale = 1}) =>
      _enqueue(() async {
        final icons = await renderTrayFace(mood, scale: scale);
        // Rendering five sizes takes long enough for the mood to have moved
        // on. Writing this frame now would leave the tray showing a mood we
        // already know is stale, and the next real change might be minutes
        // away.
        if (token != _token) return;
        await _tray.setIcon(icons, tooltip: MoodFace.of(mood).tooltip);
      });

  Future<void> _enqueue(Future<void> Function() write) {
    _queue = _queue.then((_) => write()).catchError((Object _) {
      // No tray host, or a host that went away mid-update. The icon is a
      // nicety; nothing here may be allowed to disturb the engine.
    });
    return _queue;
  }

  Future<void> dispose() async {
    _demo?.cancel();
    await _sub?.cancel();
  }
}
