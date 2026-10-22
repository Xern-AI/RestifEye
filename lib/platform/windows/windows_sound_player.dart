// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../interfaces/app_log.dart';
import '../interfaces/sound_player.dart';

/// Plays the user's own Windows sound scheme by event name, the Windows
/// counterpart of freedesktop sound-theme ids: no audio files shipped, and a
/// user who silenced an event in Control Panel → Sound hears nothing.
///
/// `SND_NODEFAULT` keeps a missing event silent instead of the default beep,
/// and `SND_SYSTEM` puts the sound on the system-sounds volume slider, where
/// a user expects a notification sound to live.
class WindowsSoundPlayer implements SoundPlayer {
  WindowsSoundPlayer({required this.log, this.enabled = true});

  final AppLog log;
  bool _reported = false;

  @override
  bool enabled;

  @override
  Future<void> play(AppSound sound) async {
    if (!enabled) return;
    try {
      using((arena) {
        final flags = SND_FLAGS(
          SND_ALIAS | SND_ASYNC | SND_NODEFAULT | SND_SYSTEM,
        );
        PlaySound(arena.pcwstr(soundAlias(sound)), null, flags);
      });
    } on Object catch (e) {
      if (!_reported) log.failure('sound', e);
      _reported = true;
    }
  }
}

/// Windows sound-scheme event names, chosen to match the Linux sounds'
/// intent: a gentle reminder, an attention cue, and a soft "done".
String soundAlias(AppSound sound) => switch (sound) {
  AppSound.warning => 'Notification.Reminder',
  AppSound.breakStarting => 'SystemNotification',
  AppSound.breakOver => 'SystemAsterisk',
};
