// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../core/models/activity.dart';

/// Turns a per-tick activity kind into closed [ActivitySlice]s.
/// A slice is emitted whenever the kind changes; [flush] closes the
/// current slice early (shutdown, periodic crash-safety).
class ActivityRecorder {
  ActivityRecorder(this._sink);

  final Future<void> Function(ActivitySlice slice) _sink;

  SliceKind? _kind;
  DateTime? _start;

  void observe(DateTime now, SliceKind kind) {
    if (_kind == null) {
      _kind = kind;
      _start = now;
      return;
    }
    if (kind == _kind) return;
    _emit(now);
    _kind = kind;
    _start = now;
  }

  /// Persists the in-progress slice up to [now] and restarts it, so at most
  /// one flush interval of history can be lost on a crash.
  Future<void> flush(DateTime now) async {
    if (_kind == null || now.isBefore(_start!)) return;
    if (now.difference(_start!) < const Duration(seconds: 1)) return;
    await _emit(now);
    _start = now;
  }

  Future<void> _emit(DateTime end) async {
    final start = _start!;
    if (end.difference(start) < const Duration(seconds: 1)) return;
    await _sink(ActivitySlice(start: start, end: end, kind: _kind!));
  }
}
