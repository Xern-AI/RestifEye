/// A moment in the break cycle worth hearing.
///
/// Mapped to freedesktop sound-naming-spec ids by the platform adapter, so we
/// inherit the user's chosen sound theme instead of shipping our own audio.
enum AppSound {
  /// Heads-up: a break comes due shortly (accompanies the notification).
  warning,

  /// A break is taking over the screen now.
  breakStarting,

  /// The break is over — back to work.
  breakOver,
}

/// Plays short UI sounds. Always best-effort: audio is a nicety, and no
/// failure here may ever surface to the user or delay a break.
abstract interface class SoundPlayer {
  Future<void> play(AppSound sound);

  /// Reflects the Settings toggle; when false, [play] is a no-op.
  set enabled(bool value);
}

/// Used in tests and wherever audio is unavailable.
class SilentSoundPlayer implements SoundPlayer {
  final List<AppSound> played = [];

  @override
  bool enabled = true;

  @override
  Future<void> play(AppSound sound) async {
    if (enabled) played.add(sound);
  }
}
