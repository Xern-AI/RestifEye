// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import '../core/engine/engine.dart';
import '../core/engine/phase.dart';
import '../platform/interfaces/app_log.dart';

/// Writes every break phase change and engine event to the [AppLog], so a
/// pasted log reads as the story of the break cycle.
///
/// The phase stream ticks once a second; only a change of [phaseLabel] is
/// written, never the countdown.
class PhaseLog {
  PhaseLog({required this.engine, required this.log});

  final BreakEngine engine;
  final AppLog log;

  final List<StreamSubscription<Object>> _subs = [];
  String? _last;

  void start() {
    _subs
      ..add(
        engine.phases.listen((phase) {
          final label = phaseLabel(phase);
          if (label == _last) return;
          _last = label;
          log.info('phase $label');
        }),
      )
      ..add(engine.events.listen((e) => log.info('event ${e.runtimeType}')));
  }

  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
  }
}

/// The parts of a phase that matter for reading a log, without countdowns.
String phaseLabel(EnginePhase phase) => switch (phase) {
  Monitoring(:final nextBreakKind) => 'monitoring (next ${nextBreakKind.name})',
  Warning(:final kind) => 'warning ${kind.name}',
  InBreak(:final kind, :final strict, :final held) =>
    'break ${kind.name}${strict ? ' strict' : ''}${held ? ' held' : ''}',
  Deferred(:final kind) => 'deferred ${kind.name} (busy)',
  Paused(:final reason, :final byApp) =>
    'paused ${reason.name}${byApp == null ? '' : ' by $byApp'}',
};
