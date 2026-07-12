import 'dart:math';

import 'package:breaktime/core/models/break_kind.dart';
import 'package:breaktime/core/models/exercise.dart';
import 'package:breaktime/services/exercise_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deck has both tiers and unique, stable ids', () {
    final ids = exerciseDeck.map((e) => e.id).toSet();
    expect(ids.length, exerciseDeck.length, reason: 'duplicate exercise id');
    expect(exerciseDeck.where((e) => e.tier == BreakKind.micro), isNotEmpty);
    expect(exerciseDeck.where((e) => e.tier == BreakKind.long), isNotEmpty);
  });

  test('picks only exercises of the requested tier', () {
    final picker = ExercisePicker(random: Random(1));
    for (var i = 0; i < 50; i++) {
      expect(picker.pick(BreakKind.micro).tier, BreakKind.micro);
      expect(picker.pick(BreakKind.long).tier, BreakKind.long);
    }
  });

  test('never picks an opted-out exercise while alternatives exist', () {
    final picker = ExercisePicker(
      random: Random(2),
      optOuts: {'eyes_palming', 'eyes_blink'},
    );
    for (var i = 0; i < 100; i++) {
      final picked = picker.pick(BreakKind.micro);
      expect(picked.id, isNot(isIn(['eyes_palming', 'eyes_blink'])));
    }
  });

  test('falls back to the full tier if everything is opted out', () {
    final allMicro = exerciseDeck
        .where((e) => e.tier == BreakKind.micro)
        .map((e) => e.id)
        .toSet();
    final picker = ExercisePicker(random: Random(3), optOuts: allMicro);
    expect(picker.pick(BreakKind.micro).tier, BreakKind.micro);
  });

  test('avoids immediate repeats most of the time', () {
    final picker = ExercisePicker(random: Random(4));
    var repeats = 0;
    var last = '';
    for (var i = 0; i < 200; i++) {
      final id = picker.pick(BreakKind.long).id;
      if (id == last) repeats++;
      last = id;
    }
    // 8 long exercises with recent-penalty: immediate repeats should be rare.
    expect(repeats, lessThan(20));
  });
}
