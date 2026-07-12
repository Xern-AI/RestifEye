import 'dart:io';

import '../interfaces/context_signals.dart';
import 'pw_dump_parser.dart';

/// Meeting/DND detection:
/// - mic/camera in use → PipeWire (`pw-dump`), standard on Fedora
/// - Do Not Disturb → GNOME's show-banners gsetting
///
/// Both degrade gracefully: a missing tool permanently disables that signal
/// instead of erroring every poll.
class LinuxContextSignals implements ContextSignals {
  bool _pwAvailable = true;
  bool _gsettingsAvailable = true;

  @override
  Future<bool> isBusy() async =>
      await _micOrCameraInUse() || await _doNotDisturb();

  Future<bool> _micOrCameraInUse() async {
    if (!_pwAvailable) return false;
    try {
      final result = await Process.run('pw-dump', const []);
      if (result.exitCode != 0) return false;
      return pwDumpShowsCapture(result.stdout as String);
    } on ProcessException {
      _pwAvailable = false; // PipeWire not present on this system
      return false;
    }
  }

  Future<bool> _doNotDisturb() async {
    if (!_gsettingsAvailable) return false;
    try {
      final result = await Process.run('gsettings', const [
        'get',
        'org.gnome.desktop.notifications',
        'show-banners',
      ]);
      if (result.exitCode != 0) return false;
      // Banners hidden ⇒ DND is on.
      return (result.stdout as String).trim() == 'false';
    } on ProcessException {
      _gsettingsAvailable = false; // not a GNOME session
      return false;
    }
  }
}
