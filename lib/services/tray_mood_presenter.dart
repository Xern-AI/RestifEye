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

  /// Seeded from the service rather than defaulting to cheerful: the mood is
  /// computed before a tray host is found, so starting at `good` would show a
  /// smile to someone the app had already concluded was skipping breaks.
  Mood _mood;

  /// Guards against two pulses overlapping — the second would otherwise race
  /// the first and leave the icon on whichever frame happened to land last.
  int _pulseToken = 0;

  Future<void> start() async {
    _sub = _moods.listen((mood) => unawaited(show(mood)));
    await _apply(_mood);
  }

  /// Renders [mood] and plays the acknowledgement pulse.
  Future<void> show(Mood mood) async {
    _mood = mood;
    if (!enabled) return _apply(Mood.good);

    final token = ++_pulseToken;
    for (final scale in _pulse) {
      if (token != _pulseToken) return; // superseded by a newer mood
      await _apply(mood, scale: scale);
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

  /// Re-asserts the current mood — used when the setting is toggled.
  Future<void> refresh() => enabled ? _apply(_mood) : _apply(Mood.good);

  Future<void> _apply(Mood mood, {double scale = 1}) async {
    try {
      final icons = await renderTrayFace(mood, scale: scale);
      await _tray.setIcon(icons, tooltip: MoodFace.of(mood).tooltip);
    } on Object {
      // No tray host, or a host that went away mid-update. The icon is a
      // nicety; nothing here may be allowed to disturb the engine.
    }
  }

  Future<void> dispose() async {
    _demo?.cancel();
    await _sub?.cancel();
  }
}
