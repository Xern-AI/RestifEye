// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Signals that the user should not be interrupted right now.
abstract interface class ContextSignals {
  /// True when the microphone/camera is in use or Do Not Disturb is on.
  /// Implementations must return `false` on backend errors — never throw.
  Future<bool> isBusy();
}
