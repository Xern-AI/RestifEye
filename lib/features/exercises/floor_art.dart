// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

import 'figure_rig.dart';

/// Which ground-plane animation to draw.
///
/// These are separate from [BodyMode] because they are all seen from the
/// side with the trunk near horizontal, and they all need a floor line to
/// read at all — a plank without a floor is just a figure falling over.
enum FloorMode {
  plank,
  pushUp,
  mountainClimber,
  catCow,
  gluteBridge,
  superman,
  hipFlexor,
}

/// The same jointed figure as [BodyArtPainter], laid out on the floor.
class FloorArtPainter extends CustomPainter {
  FloorArtPainter({required this.t, required this.mode, required this.scheme});

  final double t;
  final FloorMode mode;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = u * 0.038
      ..color = scheme.primary;
    final prop = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = u * 0.02
      ..color = scheme.tertiary.withValues(alpha: 0.55);

    final wave = sin(t * 2 * pi);
    final phase = (wave + 1) / 2;

    ArtProps(canvas, size, prop).floor(_floorY);
    _rigFor(mode, wave, phase).paint(canvas, size, stroke);
  }

  /// Where the floor sits for each pose, so that hands, knees or heels land
  /// on it rather than near it.
  double get _floorY => switch (mode) {
    FloorMode.plank || FloorMode.mountainClimber => 0.86,
    FloorMode.pushUp => 0.88,
    FloorMode.catCow => 0.88,
    FloorMode.gluteBridge => 0.86,
    FloorMode.superman => 0.86,
    FloorMode.hipFlexor => 0.9,
  };

  FigureRig _rigFor(FloorMode mode, double wave, double phase) {
    switch (mode) {
      // Held positions: the only honest animation is the breathing and the
      // tremble, so that is all they get.
      case FloorMode.plank:
        return FigureRig(
          hip: Offset(0.5, 0.6 + 0.006 * sin(t * 12 * pi)),
          torsoAngle: pi / 2 + 0.08,
          headTilt: 0.35,
          legL: Limb.aim(-pi / 2 - 0.2, bend: -0.05),
          legR: Limb.aim(-pi / 2 - 0.28, bend: 0.05),
          armL: Limb.aim(pi - 0.04, bend: -1.44),
          armR: Limb.aim(pi + 0.04, bend: -1.56),
        );

      case FloorMode.pushUp:
        final push = phase;
        return FigureRig(
          hip: Offset(0.5, 0.56 + push * 0.07),
          torsoAngle: pi / 2 + 0.07,
          headTilt: 0.3,
          legL: Limb.aim(-pi / 2 - 0.18, bend: -0.05),
          legR: Limb.aim(-pi / 2 - 0.26, bend: 0.05),
          armL: Limb.aim(pi + push * 0.5, bend: -push * 1.0),
          armR: Limb.aim(pi + push * 0.6, bend: -push * 1.05),
        );

      // The head is to the right, so the knee has to travel that way. Turning
      // the thigh the short way round swung it up into the air instead.
      case FloorMode.mountainClimber:
        final drive = phase;
        final thigh = -pi / 2 - 0.2 - drive * 2.2;
        return FigureRig(
          hip: const Offset(0.5, 0.58),
          torsoAngle: pi / 2 + 0.06,
          headTilt: 0.32,
          legL: Limb.aim(-pi / 2 - 0.26, bend: -0.05),
          legR: Limb.aim(thigh, bend: 0.05 + drive * 1.3),
          armL: Limb.aim(pi - 0.04),
          armR: Limb.aim(pi + 0.06),
        );

      // Positive wave rounds the back (cat), negative lets it sag (cow).
      case FloorMode.catCow:
        return FigureRig(
          hip: const Offset(0.44, 0.58),
          torsoAngle: pi / 2 + 0.04,
          torsoBend: -wave * 0.34,
          headTilt: 0.25 + wave * 0.45,
          legUpper: 0.12,
          legLower: 0.12,
          armL: Limb.aim(pi - 0.06, bend: 0.03),
          armR: Limb.aim(pi + 0.04, bend: -0.03),
          legL: Limb.aim(pi + 0.02, bend: 1.5),
          legR: Limb.aim(pi + 0.1, bend: 1.44),
        );

      // Lying on the back, head to the left: the arms rest along the floor
      // pointing at the feet, which is what keeps the shape from reading as
      // one long diagonal stick.
      case FloorMode.gluteBridge:
        final lift = phase;
        return FigureRig(
          hip: Offset(0.56, 0.76 - lift * 0.15),
          torsoAngle: -pi / 2 - 0.12 - lift * 0.3,
          headTilt: -0.15,
          legL: Limb.aim(0.8, bend: 2.4),
          legR: Limb.aim(0.95, bend: 2.25),
          armL: Limb.aim(pi / 2 + 0.12, bend: 0.06),
          armR: Limb.aim(pi / 2 + 0.2, bend: 0.06),
        );

      case FloorMode.superman:
        final lift = phase;
        return FigureRig(
          hip: const Offset(0.48, 0.78),
          torsoAngle: pi / 2 - 0.14 - lift * 0.2,
          headTilt: -0.25,
          armL: Limb.aim(pi / 2 + 0.1 - lift * 0.6),
          armR: Limb.aim(pi / 2 - lift * 0.6),
          legL: Limb.aim(-pi / 2 + 0.06 + lift * 0.5),
          legR: Limb.aim(-pi / 2 - 0.04 + lift * 0.5),
        );

      case FloorMode.hipFlexor:
        final press = phase;
        return FigureRig(
          hip: Offset(0.44, 0.62 + press * 0.04),
          torsoAngle: -0.05,
          legR: Limb.aim(pi - 0.75 - press * 0.12, bend: 0.75 + press * 0.12),
          legL: Limb.aim(pi + 0.62, bend: 0.95),
          armR: Limb.aim(pi - 0.55, bend: -0.15),
          armL: Limb.aim(pi - 0.32, bend: -0.1),
        );
    }
  }

  @override
  bool shouldRepaint(FloorArtPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.mode != mode ||
      oldDelegate.scheme != scheme;
}
