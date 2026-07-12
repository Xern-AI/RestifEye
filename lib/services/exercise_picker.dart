import 'dart:math';

import '../core/models/break_kind.dart';
import '../core/models/exercise.dart';

/// Picks an exercise for a break: matching tier, honoring opt-outs, and
/// heavily de-prioritizing recently shown ones so the deck feels fresh.
class ExercisePicker {
  ExercisePicker({
    this._deck = exerciseDeck,
    Set<String> optOuts = const {},
    Random? random,
  }) : _optOuts = {...optOuts},
       _random = random ?? Random();

  final List<Exercise> _deck;
  final Set<String> _optOuts;
  final Random _random;
  final List<String> _recent = [];

  static const _recentWindow = 3;
  static const _recentWeight = 1;
  static const _freshWeight = 10;

  set optOuts(Set<String> ids) {
    _optOuts
      ..clear()
      ..addAll(ids);
  }

  Exercise pick(BreakKind tier) {
    var candidates = _deck
        .where((e) => e.tier == tier && !_optOuts.contains(e.id))
        .toList();
    if (candidates.isEmpty) {
      // Everything opted out — fall back to the full tier rather than crash.
      candidates = _deck.where((e) => e.tier == tier).toList();
    }

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
