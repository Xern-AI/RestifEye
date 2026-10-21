// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../interfaces/tray_support.dart';

/// Windows always has a notification area, so there is never anything to fix.
///
/// Windows 11 does hide new icons in the overflow menu until the user pins
/// them; that is the user's choice to make, and no API may make it for them.
class WindowsTraySupport implements TrayHostSupport {
  const WindowsTraySupport();

  static const _support = TraySupport(
    TrayState.working,
    location: 'the taskbar corner',
  );

  @override
  Future<TraySupport> check() async => _support;

  @override
  Future<TraySupport> enable() async => _support;
}
