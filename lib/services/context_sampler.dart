// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../platform/interfaces/context_signals.dart';
import '../platform/interfaces/presentation_signals.dart';
import 'polled_value.dart';

/// Rate-limits busy checks: `pw-dump` is too heavy to run every second,
/// and busy state only matters when a break is close.
class ContextSampler {
  ContextSampler(ContextSignals signals, {Duration ttl = _defaultTtl})
    : _cache = PolledValue(probe: signals.isBusy, initial: false, ttl: ttl);

  static const _defaultTtl = Duration(seconds: 5);

  final PolledValue<bool> _cache;

  Duration get ttl => _cache.ttl;
  bool get value => _cache.value;

  /// Refreshes when [relevant] and the cached value is older than [ttl].
  /// Never runs two probes concurrently.
  Future<void> refreshIfNeeded({
    required bool relevant,
    required DateTime now,
  }) => _cache.refreshIfNeeded(relevant: relevant, now: now);
}

/// Rate-limits "is something playing fullscreen" checks.
///
/// Unlike [ContextSampler] this is polled **unconditionally**, not only when
/// a break is close: the pause has to engage while the film is playing, which
/// is exactly when no break is near. The probe is two D-Bus calls — far
/// cheaper than the process spawn behind the busy check — so the constant
/// cadence is affordable.
class PresentationSampler {
  PresentationSampler(
    PresentationSignals signals, {
    Duration ttl = const Duration(seconds: 5),
  }) : _cache = PolledValue(
         probe: signals.sample,
         initial: PresentationState.idle,
         ttl: ttl,
       );

  final PolledValue<PresentationState> _cache;

  PresentationState get value => _cache.value;

  Future<void> refresh(DateTime now) =>
      _cache.refreshIfNeeded(relevant: true, now: now);
}
