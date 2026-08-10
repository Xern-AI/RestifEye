// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import 'body_art.dart';
import 'eye_art.dart';

/// Theme-aware looping illustration for an exercise.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({super.key, required this.art, this.size = 220});

  final ExerciseArt art;
  final double size;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // One line per art, and still exhaustively checked: the switch
          // yields the *mode*, and the painter is chosen from its type. The
          // previous form repeated the painter construction in every arm,
          // which was twelve near-identical blocks before the deck grew.
          final mode = switch (widget.art) {
            ExerciseArt.eyesFarNear => EyeMode.farNear,
            ExerciseArt.eyesPalming => EyeMode.palming,
            ExerciseArt.eyesFigureEight => EyeMode.figureEight,
            ExerciseArt.eyesBlink => EyeMode.blink,
            ExerciseArt.headRoll => BodyMode.headRoll,
            ExerciseArt.chinTuck => BodyMode.chinTuck,
            ExerciseArt.shoulders => BodyMode.shoulders,
            ExerciseArt.wrists => BodyMode.wrists,
            ExerciseArt.posture => BodyMode.posture,
            ExerciseArt.sideStretch => BodyMode.sideStretch,
            ExerciseArt.walk => BodyMode.walk,
            ExerciseArt.breathe => BodyMode.breathe,
            ExerciseArt.neckTilt => BodyMode.neckTilt,
            ExerciseArt.chestOpen => BodyMode.chestOpen,
            ExerciseArt.torsoTwist => BodyMode.torsoTwist,
            ExerciseArt.forwardFold => BodyMode.forwardFold,
            ExerciseArt.calfRaise => BodyMode.calfRaise,
            ExerciseArt.armCircles => BodyMode.armCircles,
            ExerciseArt.squat => BodyMode.squat,
            ExerciseArt.lunge => BodyMode.lunge,
            ExerciseArt.marchInPlace => BodyMode.marchInPlace,
            ExerciseArt.jumpingJacks => BodyMode.jumpingJacks,
          };
          final painter = mode is EyeMode
              ? EyeArtPainter(t: t, mode: mode, scheme: scheme)
              : BodyArtPainter(t: t, mode: mode as BodyMode, scheme: scheme);
          return CustomPaint(size: Size.square(widget.size), painter: painter);
        },
      ),
    );
  }
}
