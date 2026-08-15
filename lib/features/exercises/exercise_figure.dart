// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import 'body_art.dart';
import 'eye_art.dart';
import 'floor_art.dart';

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
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: painterFor(widget.art, _controller.value, scheme),
        ),
      ),
    );
  }
}

/// One line per art, and still exhaustively checked: adding an exercise
/// without drawing it is a compile error rather than a blank overlay.
CustomPainter painterFor(ExerciseArt art, double t, ColorScheme scheme) {
  EyeArtPainter eye(EyeMode mode) =>
      EyeArtPainter(t: t, mode: mode, scheme: scheme);
  BodyArtPainter body(BodyMode mode) =>
      BodyArtPainter(t: t, mode: mode, scheme: scheme);
  FloorArtPainter floor(FloorMode mode) =>
      FloorArtPainter(t: t, mode: mode, scheme: scheme);

  return switch (art) {
    ExerciseArt.eyesFarNear => eye(EyeMode.farNear),
    ExerciseArt.eyesPalming => eye(EyeMode.palming),
    ExerciseArt.eyesFigureEight => eye(EyeMode.figureEight),
    ExerciseArt.eyesBlink => eye(EyeMode.blink),
    ExerciseArt.eyesRoll => eye(EyeMode.roll),
    ExerciseArt.eyesScan => eye(EyeMode.scan),
    ExerciseArt.eyesDiagonal => eye(EyeMode.diagonal),
    ExerciseArt.eyesZoom => eye(EyeMode.zoom),
    ExerciseArt.eyesSqueeze => eye(EyeMode.squeeze),
    ExerciseArt.eyesMassage => eye(EyeMode.massage),
    ExerciseArt.headRoll => body(BodyMode.headRoll),
    ExerciseArt.chinTuck => body(BodyMode.chinTuck),
    ExerciseArt.shoulders => body(BodyMode.shoulders),
    ExerciseArt.wrists => body(BodyMode.wrists),
    ExerciseArt.posture => body(BodyMode.posture),
    ExerciseArt.sideStretch => body(BodyMode.sideStretch),
    ExerciseArt.walk => body(BodyMode.walk),
    ExerciseArt.breathe => body(BodyMode.breathe),
    ExerciseArt.neckTilt => body(BodyMode.neckTilt),
    ExerciseArt.chestOpen => body(BodyMode.chestOpen),
    ExerciseArt.torsoTwist => body(BodyMode.torsoTwist),
    ExerciseArt.forwardFold => body(BodyMode.forwardFold),
    ExerciseArt.calfRaise => body(BodyMode.calfRaise),
    ExerciseArt.armCircles => body(BodyMode.armCircles),
    ExerciseArt.squat => body(BodyMode.squat),
    ExerciseArt.lunge => body(BodyMode.lunge),
    ExerciseArt.marchInPlace => body(BodyMode.marchInPlace),
    ExerciseArt.jumpingJacks => body(BodyMode.jumpingJacks),
    ExerciseArt.ankleCircles => body(BodyMode.ankleCircles),
    ExerciseArt.bladeSqueeze => body(BodyMode.bladeSqueeze),
    ExerciseArt.legExtension => body(BodyMode.legExtension),
    ExerciseArt.neckPress => body(BodyMode.neckPress),
    ExerciseArt.wallAngels => body(BodyMode.wallAngels),
    ExerciseArt.doorwayStretch => body(BodyMode.doorwayStretch),
    ExerciseArt.quadStretch => body(BodyMode.quadStretch),
    ExerciseArt.hamstringStretch => body(BodyMode.hamstringStretch),
    ExerciseArt.deskPushUp => body(BodyMode.deskPushUp),
    ExerciseArt.balance => body(BodyMode.balance),
    ExerciseArt.hipCircles => body(BodyMode.hipCircles),
    ExerciseArt.heelToeWalk => body(BodyMode.heelToeWalk),
    ExerciseArt.wallSit => body(BodyMode.wallSit),
    ExerciseArt.buttKicks => body(BodyMode.buttKicks),
    ExerciseArt.shadowBox => body(BodyMode.shadowBox),
    ExerciseArt.jumpRope => body(BodyMode.jumpRope),
    ExerciseArt.plank => floor(FloorMode.plank),
    ExerciseArt.pushUp => floor(FloorMode.pushUp),
    ExerciseArt.mountainClimber => floor(FloorMode.mountainClimber),
    ExerciseArt.catCow => floor(FloorMode.catCow),
    ExerciseArt.gluteBridge => floor(FloorMode.gluteBridge),
    ExerciseArt.superman => floor(FloorMode.superman),
    ExerciseArt.hipFlexor => floor(FloorMode.hipFlexor),
  };
}
