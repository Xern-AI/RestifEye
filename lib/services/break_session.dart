import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/engine/events.dart';
import '../core/models/exercise.dart';
import '../data/exercise_log_repository.dart';
import '../platform/interfaces/overlay_controller.dart';
import 'exercise_picker.dart';
import 'providers.dart';

/// The exercise for the break currently on screen (null outside breaks).
/// Also drives the window takeover and the exercise log.
class BreakSessionNotifier extends Notifier<Exercise?> {
  StreamSubscription<EngineEvent>? _sub;
  late ExercisePicker _picker;

  @override
  Exercise? build() {
    _picker = ref.watch(exercisePickerProvider);
    final service = ref.watch(engineServiceProvider);
    final overlay = ref.watch(overlayControllerProvider);
    final log = ref.watch(exerciseLogRepositoryProvider);

    _sub?.cancel();
    _sub = service.engine.events.listen((event) {
      switch (event) {
        case BreakStarted(:final kind, :final strict):
          state = _picker.pick(kind);
          unawaited(overlay.enterBreak(strict: strict));
        case BreakCompleted():
          _closeSession(log, completed: true, at: event.at, overlay: overlay);
        case BreakEscaped():
          _closeSession(log, completed: false, at: event.at, overlay: overlay);
        case BreakSnoozed():
          state = null;
          unawaited(overlay.exitBreak());
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
    required OverlayController overlay,
  }) {
    final exercise = state;
    if (exercise != null) {
      unawaited(
        log.record(exerciseId: exercise.id, completed: completed, at: at),
      );
    }
    state = null;
    unawaited(overlay.exitBreak());
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
