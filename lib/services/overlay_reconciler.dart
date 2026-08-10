// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/phase.dart';
import '../platform/interfaces/overlay_controller.dart';
import 'providers.dart';

/// The window state a phase requires. Pure, so it is exhaustively testable
/// without a window, a compositor, or a running engine.
///
/// Strict breaks always take the full screen regardless of the user's
/// preference — a strict break in a background window would be no break.
BreakWindowState desiredWindowState(
  EnginePhase phase, {
  required bool fullscreenPreferred,
}) => switch (phase) {
  InBreak(:final strict) => BreakWindowState(
    inBreak: true,
    strict: strict,
    fullscreen: fullscreenPreferred || strict,
  ),
  Monitoring() ||
  Warning() ||
  Deferred() ||
  Paused() => BreakWindowState.normal,
};

/// Keeps the window in lockstep with the engine phase.
///
/// Level-triggered by design. The previous implementation drove the window
/// from one-shot engine *events*, so any path that ended a break without
/// emitting the exact expected event left the window fullscreen, on top and
/// unclosable — which is precisely how a user got trapped. Re-deriving the
/// desired state from the current phase on every tick means a missed event
/// costs one second of staleness instead of a wedged app.
final overlayReconcilerProvider = Provider<void>((ref) {
  final overlay = ref.watch(overlayControllerProvider);
  final engine = ref.watch(engineServiceProvider).engine;

  final sub = engine.phases.listen((phase) {
    final fullscreen =
        ref.read(generalSettingsProvider).value?.fullscreenOverlay ?? true;
    unawaited(
      overlay.apply(desiredWindowState(phase, fullscreenPreferred: fullscreen)),
    );

    // A timed pause lapses inside the engine, so the UI's pause state has to
    // follow the engine rather than the other way round.
    ref.read(pausedProvider.notifier).syncFromEngine((
      paused: phase is Paused && phase.byUser,
      until: phase is Paused ? phase.until : null,
    ));
  });
  ref.onDispose(sub.cancel);
});
