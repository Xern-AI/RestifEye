// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// Looks up the newest released version.
abstract interface class UpdateChecker {
  /// Latest release version (e.g. "1.2.0"), or null when unavailable.
  /// Must not throw — offline is normal.
  Future<String?> latestVersion();
}
