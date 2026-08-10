// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

/// A TTL-cached value refreshed from an async probe, with in-flight
/// de-duplication.
///
/// Platform probes here are expensive in different ways — `pw-dump` spawns a
/// process, D-Bus calls cross a socket — and the 1 Hz engine tick must never
/// wait on either. Everything reads the last known value while at most one
/// refresh runs behind it.
class PolledValue<T> {
  PolledValue({
    required this._probe,
    required T initial,
    this.ttl = const Duration(seconds: 5),
  }) : _value = initial;

  final Future<T> Function() _probe;
  final Duration ttl;

  T _value;
  DateTime? _sampledAt;
  Future<void>? _inFlight;

  T get value => _value;

  /// Refreshes when [relevant] and the cached value is older than [ttl].
  /// Never runs two probes concurrently.
  Future<void> refreshIfNeeded({
    required bool relevant,
    required DateTime now,
  }) {
    if (!relevant) return Future.value();
    final age = _sampledAt == null ? null : now.difference(_sampledAt!);
    if (age != null && age < ttl) return Future.value();
    return _inFlight ??= _probe()
        .then((result) {
          _value = result;
          _sampledAt = now;
        })
        .whenComplete(() => _inFlight = null);
  }
}
