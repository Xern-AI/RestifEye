// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/core/models/break_kind.dart';
import 'package:restifeye/core/models/exercise.dart';
import 'package:restifeye/features/exercises/exercise_figure.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F62));

  // The art switch is exhaustive, so a missing drawing is a compile error
  // rather than a blank overlay. This covers the other half: that every one
  // of them actually paints, at every point in its loop, without throwing.
  test('every art paints across its whole loop', () {
    for (final art in ExerciseArt.values) {
      for (var i = 0; i < 16; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        expect(
          () => painterFor(
            art,
            i / 16,
            scheme,
          ).paint(canvas, const Size(200, 200)),
          returnsNormally,
          reason: '${art.name} at t=${i / 16}',
        );
        recorder.endRecording().dispose();
      }
    }
  });

  test('every exercise in the deck is illustrated and reachable', () {
    final drawn = <ExerciseArt>{};
    for (final exercise in exerciseDeck) {
      expect(exercise.steps, isNotEmpty, reason: exercise.id);
      drawn.add(exercise.art);
    }
    // Every art is used by at least one exercise: an unused one is dead
    // drawing code that will quietly rot.
    expect(drawn, containsAll(ExerciseArt.values));
  });

  // A ceiling the user can choose must leave something to show at every
  // level, or the picker falls back and the setting silently does nothing.
  test('each tier and intensity ceiling has exercises to offer', () {
    for (final tier in BreakKind.values) {
      for (final ceiling in ExerciseIntensity.values) {
        final available = exerciseDeck.where(
          (e) => e.tier == tier && e.intensity.allowedBy(ceiling),
        );
        expect(
          available.length,
          greaterThanOrEqualTo(3),
          reason: '${tier.name} at ${ceiling.name}',
        );
      }
    }
  });
}
