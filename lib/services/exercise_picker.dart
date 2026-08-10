// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import '../core/models/break_kind.dart';
import '../core/models/exercise.dart';

/// Picks an exercise for a break: matching tier, within the user's intensity
/// ceiling, honoring opt-outs, and heavily de-prioritizing recently shown
/// ones so the deck feels fresh.
class ExercisePicker {
  ExercisePicker({
    this._deck = exerciseDeck,
    Set<String> optOuts = const {},
    this.maxIntensity = ExerciseIntensity.medium,
    Random? random,
  }) : _optOuts = {...optOuts},
       _random = random ?? Random();

  final List<Exercise> _deck;
  final Set<String> _optOuts;
  final Random _random;
  final List<String> _recent = [];

  /// Ceiling on how demanding a picked exercise may be. Public and mutable,
  /// mirroring [optOuts]: Settings pushes changes into the live picker so a
  /// user who lowers it mid-session is not shown squats on the next break.
  ExerciseIntensity maxIntensity;

  static const _recentWindow = 3;
  static const _recentWeight = 1;
  static const _freshWeight = 10;

  set optOuts(Set<String> ids) {
    _optOuts
      ..clear()
      ..addAll(ids);
  }

  Exercise pick(BreakKind tier) {
    final inTier = _deck.where((e) => e.tier == tier).toList();
    var candidates = inTier
        .where(
          (e) =>
              !_optOuts.contains(e.id) && e.intensity.allowedBy(maxIntensity),
        )
        .toList();

    if (candidates.isEmpty) {
      // Opt-outs and the ceiling together ruled everything out. Drop the
      // opt-outs first: showing an exercise someone muted is a smaller broken
      // promise than showing one they cannot do where they are sitting.
      candidates = inTier
          .where((e) => e.intensity.allowedBy(maxIntensity))
          .toList();
    }
    // Ceiling below every exercise in the tier — fall back rather than crash.
    if (candidates.isEmpty) candidates = inTier;

    final weights = [
      for (final e in candidates)
        _recent.contains(e.id) ? _recentWeight : _freshWeight,
    ];
    final total = weights.reduce((a, b) => a + b);
    var roll = _random.nextInt(total);
    var chosen = candidates.last;
    for (var i = 0; i < candidates.length; i++) {
      roll -= weights[i];
      if (roll < 0) {
        chosen = candidates[i];
        break;
      }
    }

    _recent.add(chosen.id);
    if (_recent.length > _recentWindow) _recent.removeAt(0);
    return chosen;
  }
}
