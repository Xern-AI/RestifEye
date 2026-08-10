// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Launch-at-login control.
abstract interface class Autostart {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}
