import 'package:restifeye/platform/fake/fake_signals.dart';
import 'package:restifeye/services/context_sampler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not probe when irrelevant', () async {
    final signals = _CountingSignals();
    final sampler = ContextSampler(signals);
    await sampler.refreshIfNeeded(relevant: false, now: DateTime(2026));
    expect(signals.probes, 0);
    expect(sampler.value, isFalse);
  });

  test('probes when relevant and honors the TTL', () async {
    final signals = _CountingSignals()..busy = true;
    final sampler = ContextSampler(signals, ttl: const Duration(seconds: 5));
    final t0 = DateTime(2026, 7, 10, 10);

    await sampler.refreshIfNeeded(relevant: true, now: t0);
    expect(sampler.value, isTrue);
    expect(signals.probes, 1);

    // Within TTL: cached.
    await sampler.refreshIfNeeded(
      relevant: true,
      now: t0.add(const Duration(seconds: 3)),
    );
    expect(signals.probes, 1);

    // Past TTL: probed again.
    signals.busy = false;
    await sampler.refreshIfNeeded(
      relevant: true,
      now: t0.add(const Duration(seconds: 6)),
    );
    expect(signals.probes, 2);
    expect(sampler.value, isFalse);
  });
}

class _CountingSignals extends FakeContextSignals {
  int probes = 0;

  @override
  Future<bool> isBusy() {
    probes++;
    return super.isBusy();
  }
}
