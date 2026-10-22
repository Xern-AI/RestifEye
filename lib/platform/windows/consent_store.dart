// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'user_registry.dart';

/// Where Windows records which apps used the microphone and camera, the same
/// data behind the privacy indicator in the taskbar.
///
/// Under each device key there is one subkey per Store app, plus a
/// `NonPackaged` subkey holding one subkey per desktop program (its path with
/// `\` written as `#`). Each carries `LastUsedTimeStart` and
/// `LastUsedTimeStop` as FILETIME values; a stop of 0 after a start means the
/// device is open right now.
const consentStorePath =
    r'Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager'
    r'\ConsentStore';

const consentDevices = ['microphone', 'webcam'];

/// One app's record for one device.
class CaptureUse {
  const CaptureUse({required this.app, this.start, this.stop});

  final String app;
  final int? start;
  final int? stop;

  /// Requires a real start as well as a zero stop: an app that was allowed
  /// the device but never opened it can carry no timestamps or zeroes, and
  /// must not read as a meeting.
  bool get inUse => (start ?? 0) != 0 && stop == 0;
}

/// Every app entry under both devices, Store apps and desktop programs alike.
List<CaptureUse> readConsentStore(UserRegistry registry) {
  final uses = <CaptureUse>[];
  for (final device in consentDevices) {
    final base = '$consentStorePath\\$device';
    for (final app in registry.subkeys(base)) {
      if (app.toLowerCase() == 'nonpackaged') {
        final nonPackaged = '$base\\NonPackaged';
        for (final program in registry.subkeys(nonPackaged)) {
          uses.add(_entry(registry, '$nonPackaged\\$program', program));
        }
      } else {
        uses.add(_entry(registry, '$base\\$app', app));
      }
    }
  }
  return uses;
}

CaptureUse _entry(UserRegistry registry, String path, String app) => CaptureUse(
  app: app,
  start: registry.readInt(path, 'LastUsedTimeStart'),
  stop: registry.readInt(path, 'LastUsedTimeStop'),
);

/// The first app holding the microphone or camera open, or null.
String? captureInUse(Iterable<CaptureUse> uses) {
  for (final use in uses) {
    if (use.inUse) return use.app;
  }
  return null;
}
