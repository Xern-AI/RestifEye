// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:typed_data';

import '../../app/brand.dart';
import '../interfaces/autostart.dart';
import 'user_registry.dart';

/// Start with Windows through the per-user `Run` key, for this unpackaged
/// build. (The Store build will use a StartupTask in its manifest instead.)
///
/// Task Manager's Startup tab does not delete a `Run` entry when the user
/// disables it; it records the choice under `StartupApproved\Run`. Reading
/// only the `Run` key would report "on" for an app the user switched off.
class WindowsAutostart implements Autostart {
  WindowsAutostart({required this.registry, required this.executable});

  static const runPath = r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const approvedPath =
      r'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved'
      r'\Run';
  static const valueName = Brand.appName;

  final UserRegistry registry;
  final String executable;

  @override
  Future<bool> isEnabled() async =>
      registry.readString(runPath, valueName) != null &&
      !startupApprovedDisabled(registry.readBinary(approvedPath, valueName));

  /// Enabling from Settings also overrides a Task Manager "disabled" mark:
  /// the user has just asked for it here, which is the newer decision. It
  /// writes the same "enabled" mark Task Manager writes, because the first
  /// Windows test showed Task Manager still listing the app as disabled when
  /// the mark was merely deleted.
  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      registry
        ..writeString(runPath, valueName, runCommandFor(executable))
        ..writeBinary(approvedPath, valueName, startupApprovedEnabled);
    } else {
      registry
        ..deleteValue(runPath, valueName)
        ..deleteValue(approvedPath, valueName);
    }
  }

  /// Points an enabled entry at this copy of the app.
  ///
  /// Test builds arrive as zips unpacked to a new folder each time, so the
  /// entry written by an older build would keep starting that older build.
  /// Only an entry that is already on is touched, so an opt-out stays put.
  /// Returns true when it changed something.
  Future<bool> repairPath() async {
    final current = registry.readString(runPath, valueName);
    final wanted = runCommandFor(executable);
    if (current == null || current == wanted || !await isEnabled()) {
      return false;
    }
    registry.writeString(runPath, valueName, wanted);
    return true;
  }
}

/// Task Manager's "enabled" mark: `02` followed by eleven zero bytes.
final startupApprovedEnabled = Uint8List.fromList([2, ...List.filled(11, 0)]);

/// Quoted, because the folder a zip is unpacked to often contains spaces.
String runCommandFor(String executable) => '"$executable"';

/// Task Manager writes 12 bytes whose first byte is even when enabled
/// (`02`, `06`) and odd when disabled (`03`, `07`). Anything absent or
/// unreadable counts as not disabled, which is how Windows itself treats it.
bool startupApprovedDisabled(Uint8List? data) =>
    data != null && data.isNotEmpty && data.first.isOdd;
