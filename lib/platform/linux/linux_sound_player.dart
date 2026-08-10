// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../interfaces/sound_player.dart';

/// Plays freedesktop theme sounds by shelling out to whatever the desktop
/// already has.
///
/// No audio plugin, and therefore no new native library to link: the same
/// reasoning that produced the hand-rolled SNI tray. An AppImage that depends
/// on nothing runs everywhere, and a break reminder that fails to launch is
/// infinitely worse than one that is silent.
///
/// Player is probed once and cached. Every candidate is standard on GNOME/KDE
/// (libcanberra ships with both; paplay/pw-play come with PipeWire), and if
/// none is present we simply stay quiet.
class LinuxSoundPlayer implements SoundPlayer {
  LinuxSoundPlayer({this.enabled = true});

  @override
  bool enabled;

  /// freedesktop sound-naming-spec ids — the user's sound theme decides what
  /// they actually sound like.
  static const _names = {
    AppSound.warning: 'message-new-instant',
    AppSound.breakStarting: 'dialog-information',
    AppSound.breakOver: 'complete',
  };

  static const _themeDir = '/usr/share/sounds/freedesktop/stereo';

  Future<_Player?>? _probe;

  @override
  Future<void> play(AppSound sound) async {
    if (!enabled) return;
    try {
      final player = await (_probe ??= _findPlayer());
      if (player == null) return;
      final name = _names[sound]!;
      await Process.run(player.binary, player.argsFor(name));
    } on Object {
      // Sound is decoration. It must never take a break — or the app — down.
    }
  }

  Future<_Player?> _findPlayer() async {
    // canberra plays theme sounds by name and honours the user's theme, so
    // it is strictly preferred over pointing a raw player at a file path.
    if (await _exists('canberra-gtk-play')) {
      return const _Player.canberra();
    }
    for (final binary in ['paplay', 'pw-play']) {
      if (await _exists(binary)) return _Player.file(binary);
    }
    return null;
  }

  Future<bool> _exists(String binary) async {
    try {
      final result = await Process.run('which', [binary]);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }
}

class _Player {
  const _Player.canberra() : binary = 'canberra-gtk-play', _byName = true;
  const _Player.file(this.binary) : _byName = false;

  final String binary;
  final bool _byName;

  List<String> argsFor(String soundName) => _byName
      ? ['--id', soundName]
      : ['${LinuxSoundPlayer._themeDir}/$soundName.oga'];
}
