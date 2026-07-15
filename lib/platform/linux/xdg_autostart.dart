import 'dart:io';

import 'package:path/path.dart' as p;

import '../interfaces/autostart.dart';

/// Launch-at-login via the XDG autostart spec: a .desktop file in
/// ~/.config/autostart. Works on every major desktop.
class XdgAutostart implements Autostart {
  XdgAutostart({String? configHome})
    : _dir = Directory(
        p.join(
          configHome ??
              Platform.environment['XDG_CONFIG_HOME'] ??
              p.join(Platform.environment['HOME'] ?? '.', '.config'),
          'autostart',
        ),
      );

  final Directory _dir;

  File get _file => File(p.join(_dir.path, 'com.xernai.restifeye.desktop'));

  /// AppImages must relaunch via the image path, not the extracted binary.
  static String get _execPath =>
      Platform.environment['APPIMAGE'] ?? Platform.resolvedExecutable;

  @override
  Future<bool> isEnabled() => _file.exists();

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!enabled) {
      if (await _file.exists()) await _file.delete();
      return;
    }
    await _dir.create(recursive: true);
    await _file.writeAsString('''
[Desktop Entry]
Type=Application
Name=RestifEye
Comment=Break reminders that respect your flow
Exec=$_execPath
Icon=com.xernai.restifeye
Terminal=false
X-GNOME-Autostart-enabled=true
''');
  }
}
