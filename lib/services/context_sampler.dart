import '../platform/interfaces/context_signals.dart';

/// Rate-limits busy checks: `pw-dump` is too heavy to run every second,
/// and busy state only matters when a break is close.
class ContextSampler {
  ContextSampler(this._signals, {this.ttl = const Duration(seconds: 5)});

  final ContextSignals _signals;
  final Duration ttl;

  bool _value = false;
  DateTime? _sampledAt;
  Future<void>? _inFlight;

  bool get value => _value;

  /// Refreshes when [relevant] and the cached value is older than [ttl].
  /// Never runs two probes concurrently.
  Future<void> refreshIfNeeded({
    required bool relevant,
    required DateTime now,
  }) {
    if (!relevant) return Future.value();
    final age = _sampledAt == null ? null : now.difference(_sampledAt!);
    if (age != null && age < ttl) return Future.value();
    return _inFlight ??= _signals
        .isBusy()
        .then((busy) {
          _value = busy;
          _sampledAt = now;
        })
        .whenComplete(() => _inFlight = null);
  }
}
