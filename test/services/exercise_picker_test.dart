import 'dart:math';

import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/core/models/exercise.dart';
import 'package:restifeye/services/exercise_picker.dart';
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
  test('never exceeds the intensity ceiling', () {
    final picker = ExercisePicker(
      maxIntensity: ExerciseIntensity.soft,
      random: Random(7),
    );
    for (var i = 0; i < 200; i++) {
      expect(picker.pick(BreakKind.long).intensity, ExerciseIntensity.soft);
    }
  });

  test('a raised ceiling unlocks the heavier exercises', () {
    final picker = ExercisePicker(
      maxIntensity: ExerciseIntensity.heavy,
      random: Random(3),
    );
    final seen = {
      for (var i = 0; i < 400; i++) picker.pick(BreakKind.long).intensity,
    };
    expect(seen, contains(ExerciseIntensity.heavy));
  });

  // The ceiling is a physical constraint; an opt-out is a preference. When
  // they collide the preference has to yield, or there is nothing to show.
  test('the ceiling outranks opt-outs when they leave nothing', () {
    final softIds = exerciseDeck
        .where(
          (e) =>
              e.tier == BreakKind.long && e.intensity == ExerciseIntensity.soft,
        )
        .map((e) => e.id)
        .toSet();
    final picker = ExercisePicker(
      optOuts: softIds,
      maxIntensity: ExerciseIntensity.soft,
      random: Random(11),
    );
    expect(picker.pick(BreakKind.long).intensity, ExerciseIntensity.soft);
  });

  test('lowering the ceiling mid-session takes effect immediately', () {
    final picker = ExercisePicker(
      maxIntensity: ExerciseIntensity.heavy,
      random: Random(5),
    );
    picker.pick(BreakKind.long);
    picker.maxIntensity = ExerciseIntensity.soft;
    for (var i = 0; i < 100; i++) {
      expect(picker.pick(BreakKind.long).intensity, ExerciseIntensity.soft);
    }
  });
}
