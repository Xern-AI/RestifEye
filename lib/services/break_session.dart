// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/events.dart';
import '../core/models/exercise.dart';
import '../data/exercise_log_repository.dart';
import 'exercise_picker.dart';
import 'providers.dart';

/// The exercise for the break currently on screen (null outside breaks),
/// and its completion log.
///
/// It deliberately does *not* drive the window: that is
/// [overlayReconcilerProvider]'s job, derived from the engine phase. Driving
/// the window from events here is what once let a break end down a path with
/// no matching event and leave the user trapped in a full-screen window.
class BreakSessionNotifier extends Notifier<Exercise?> {
  StreamSubscription<EngineEvent>? _sub;
  late ExercisePicker _picker;

  @override
  Exercise? build() {
    _picker = ref.watch(exercisePickerProvider);
    final service = ref.watch(engineServiceProvider);
    final log = ref.watch(exerciseLogRepositoryProvider);

    _sub?.cancel();
    _sub = service.engine.events.listen((event) {
      switch (event) {
        case BreakStarted(:final kind):
          state = _picker.pick(kind);
        case BreakCompleted():
          _closeSession(log, completed: true, at: event.at);
        case BreakEscaped():
          _closeSession(log, completed: false, at: event.at);
        case BreakSnoozed() || BreakSkipped() || BreakCredited():
          // No exercise was on screen for these; nothing to log.
          state = null;
        default:
          break;
      }
    });
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  void _closeSession(
    ExerciseLogRepository log, {
    required bool completed,
    required DateTime at,
  }) {
    final exercise = state;
    if (exercise != null) {
      unawaited(
        log.record(exerciseId: exercise.id, completed: completed, at: at),
      );
    }
    state = null;
  }

  /// "Can't do this one": opt out permanently and swap in another exercise.
  Future<void> optOutCurrent() async {
    final exercise = state;
    if (exercise == null) return;
    final settings = ref.read(settingsRepositoryProvider);
    final optOuts = await settings.loadExerciseOptOuts()
      ..add(exercise.id);
    await settings.saveExerciseOptOuts(optOuts);
    _picker.optOuts = optOuts;
    state = _picker.pick(exercise.tier);
  }
}

final breakSessionProvider = NotifierProvider<BreakSessionNotifier, Exercise?>(
  BreakSessionNotifier.new,
);
