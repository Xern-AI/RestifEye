// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:convert';

/// True when the given `pw-dump` JSON output contains a running audio or
/// video *input* stream — i.e. some app is actively using the mic or camera.
///
/// Pure function so it can be tested against captured fixtures.
bool pwDumpShowsCapture(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return false;
  }
  if (decoded is! List) return false;

  for (final entry in decoded) {
    if (entry is! Map<String, Object?>) continue;
    if (entry['type'] != 'PipeWire:Interface:Node') continue;
    final info = entry['info'];
    if (info is! Map<String, Object?>) continue;
    if (info['state'] != 'running') continue;
    final props = info['props'];
    if (props is! Map<String, Object?>) continue;
    final mediaClass = props['media.class'];
    if (mediaClass == 'Stream/Input/Audio' ||
        mediaClass == 'Stream/Input/Video') {
      return true;
    }
  }
  return false;
}
