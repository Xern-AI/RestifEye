// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

import 'figure_rig.dart';

/// Which upright animation to draw. Ground-plane poses live in
/// [FloorArtPainter] instead — a body lying down is a different skeleton
/// layout, not another parameter of a standing one.
enum BodyMode {
  headRoll,
  chinTuck,
  shoulders,
  wrists,
  posture,
  sideStretch,
  walk,
  breathe,
  neckTilt,
  chestOpen,
  torsoTwist,
  forwardFold,
  calfRaise,
  armCircles,
  squat,
  lunge,
  marchInPlace,
  jumpingJacks,
  ankleCircles,
  bladeSqueeze,
  legExtension,
  neckPress,
  wallAngels,
  doorwayStretch,
  quadStretch,
  hamstringStretch,
  deskPushUp,
  balance,
  hipCircles,
  heelToeWalk,
  wallSit,
  buttKicks,
  shadowBox,
  jumpRope,
}

/// A friendly round-headed figure animating the given exercise.
/// Driven by [t] in [0,1) looping.
class BodyArtPainter extends CustomPainter {
  BodyArtPainter({required this.t, required this.mode, required this.scheme});

  final double t;
  final BodyMode mode;
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
    final props = ArtProps(canvas, size, prop);

    final wave = sin(t * 2 * pi); // -1..1
    final phase = (wave + 1) / 2; // 0..1
    final sweep = t * 2 * pi; // one full turn per loop

    // Breathing is the one exercise with no body in it: a figure standing
    // still says nothing, while an expanding ring is the instruction.
    if (mode == BodyMode.breathe) {
      final breath = 0.7 + 0.3 * phase;
      for (var i = 3; i >= 1; i--) {
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          u * 0.14 * i * breath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.strokeWidth
            ..color = scheme.primary.withValues(alpha: 0.25 + 0.25 * i / 3),
        );
      }
      return;
    }

    final rig = _rigFor(mode, wave, phase, sweep, t);
    _prosFor(mode, props, phase);
    final points = rig.solve(size);
    rig.paint(canvas, size, stroke, points);
    _extrasFor(mode, canvas, size, points, prop, phase, sweep);
  }

  /// Props are drawn before the figure so the body always overlaps its
  /// furniture rather than being cut by it.
  void _prosFor(BodyMode mode, ArtProps props, double phase) {
    switch (mode) {
      case BodyMode.wallAngels:
        props
          ..wall(0.24)
          ..floor(0.95);
      case BodyMode.wallSit:
        props
          ..wall(0.3)
          ..floor(0.95);
      case BodyMode.doorwayStretch:
        props.doorway();
      case BodyMode.deskPushUp:
        props
          ..ledge(0.6, 0.52)
          ..floor(0.95);
      case BodyMode.ankleCircles:
      case BodyMode.legExtension:
        props.chair(0.42, 0.6);
      case BodyMode.calfRaise:
      case BodyMode.heelToeWalk:
      case BodyMode.jumpRope:
      case BodyMode.buttKicks:
      case BodyMode.balance:
        props.floor(0.95);
      // Everything else is the figure alone, deliberately: an empty frame
      // reads as "anywhere", which is where most of these can be done.
      case _:
        break;
    }
  }

  FigureRig _rigFor(
    BodyMode mode,
    double wave,
    double phase,
    double sweep,
    double t,
  ) {
    switch (mode) {
      case BodyMode.breathe:
        return FigureRig();

      case BodyMode.headRoll:
        return FigureRig(
          headTilt: wave * 0.5,
          headShift: Offset(sin(wave * 0.5) * 0.02, 0),
        );

      case BodyMode.chinTuck:
        return FigureRig(headShift: Offset(0.055 - phase * 0.095, 0));

      case BodyMode.shoulders:
        return FigureRig(shoulderLift: phase * 0.05);

      case BodyMode.wrists:
        return FigureRig(
          armR: Limb.open(rightSide, 1.45, bend: -0.4 + wave * 0.85),
          armL: Limb.open(leftSide, 0.2, bend: 0.15),
        );

      case BodyMode.posture:
        final slouch = 1 - phase;
        return FigureRig(
          torsoBend: slouch * 0.75,
          torso: 0.28 - slouch * 0.035,
          headShift: Offset(slouch * 0.1, slouch * 0.015),
          shoulderLift: -slouch * 0.015,
        );

      case BodyMode.sideStretch:
        return FigureRig(
          torsoAngle: wave * 0.35,
          armR: Limb.open(rightSide, 2.85, bend: 0.25),
          armL: Limb.open(leftSide, 0.25, bend: 0.2),
        );

      case BodyMode.walk:
        return FigureRig(
          legR: Limb.aim(pi - wave * 0.34, bend: -0.12),
          legL: Limb.aim(pi + wave * 0.34, bend: 0.12),
          armR: Limb.aim(pi + 0.1 + wave * 0.42),
          armL: Limb.aim(pi - 0.1 - wave * 0.42),
        );

      case BodyMode.neckTilt:
        return FigureRig(
          headTilt: wave * 0.5,
          headShift: Offset(sin(wave * 0.5) * 0.035, 0.01),
        );

      case BodyMode.chestOpen:
        // Hands meet low behind the back — they must converge without
        // crossing, or the figure reads as tied up rather than opened out.
        return FigureRig(
          armOut: 0.2 - phase * 0.24,
          armBend: -0.05 - phase * 0.25,
          shoulderWidth: 0.05 + phase * 0.01,
        );

      case BodyMode.torsoTwist:
        final twist = wave * 0.9;
        return FigureRig(
          shoulderWidth: 0.022 + 0.03 * cos(twist).abs(),
          headTilt: twist * 0.15,
          armR: Limb.open(rightSide, 0.55 + twist * 0.4, bend: 0.35),
          armL: Limb.open(leftSide, 0.55 - twist * 0.4, bend: 0.35),
        );

      case BodyMode.forwardFold:
        final fold = 0.12 + phase * 0.95;
        return FigureRig(
          hip: const Offset(0.44, 0.66),
          torsoAngle: fold,
          armL: Limb.aim(pi + 0.08),
          armR: Limb.aim(pi - 0.08),
          legOut: 0.09,
          legBend: -0.07,
        );

      // The ankles rise with the body; the toes stay on the floor and the
      // gap between them is drawn in, which is what a calf raise looks like.
      case BodyMode.calfRaise:
        return FigureRig(
          hip: Offset(0.5, 0.68 - phase * 0.05),
          legOut: 0.08,
          armOut: 0.3,
        );

      case BodyMode.armCircles:
        return FigureRig(
          armOut: 1.45 + 0.22 * cos(sweep),
          armBend: 0.28 * sin(sweep),
        );

      case BodyMode.squat:
        final depth = 0.12 + phase * 0.5;
        return FigureRig(
          hip: Offset(0.5, 0.62 + phase * 0.1),
          legOut: depth,
          legBend: -depth,
          torsoAngle: phase * 0.16,
          armOut: 1.2,
          armBend: -0.15,
        );

      case BodyMode.lunge:
        return FigureRig(
          hip: Offset(0.47, 0.58 + phase * 0.09),
          legR: Limb.aim(pi - 0.45 - phase * 0.3, bend: 0.45 + phase * 0.3),
          legL: Limb.aim(pi + 0.5 + phase * 0.2, bend: -0.62 - phase * 0.22),
          armOut: 0.35,
          armBend: -0.9,
        );

      case BodyMode.marchInPlace:
        final right = max(0.0, wave);
        final left = max(0.0, -wave);
        return FigureRig(
          legR: Limb.aim(pi - right * 1.25, bend: right * 1.35),
          legL: Limb.aim(pi + left * 1.25, bend: -left * 1.35),
          armR: Limb.aim(pi + left * 0.7, bend: -0.5),
          armL: Limb.aim(pi - right * 0.7, bend: 0.5),
        );

      case BodyMode.jumpingJacks:
        return FigureRig(
          hip: Offset(0.5, 0.68 - sin(phase * pi) * 0.03),
          legOut: 0.1 + phase * 0.42,
          armOut: 0.25 + phase * 2.35,
        );

      // ---- seated ------------------------------------------------------
      case BodyMode.ankleCircles:
        return _seated(
          legR: Limb.aim(pi / 2, bend: pi / 2 - 0.3 + 0.3 * sin(sweep)),
          legLower: 0.125 + 0.02 * cos(sweep),
        );

      case BodyMode.legExtension:
        return _seated(legR: Limb.aim(pi / 2, bend: pi / 2 - phase * 1.45));

      case BodyMode.bladeSqueeze:
        return FigureRig(
          shoulderWidth: 0.055 - phase * 0.015,
          armOut: 1.0 + phase * 0.25,
          armBend: -1.15,
        );

      case BodyMode.neckPress:
        return FigureRig(
          headShift: Offset(-phase * 0.015, 0),
          armR: Limb.aim(1.25, bend: -1.95),
          armL: Limb.open(leftSide, 0.2),
        );

      // ---- standing, with something to lean on ---------------------------
      case BodyMode.wallAngels:
        return FigureRig(
          hip: const Offset(0.5, 0.68),
          armOut: 1.55 + phase * 0.9,
          armBend: 0.9 - phase * 0.85,
          legOut: 0.1,
        );

      case BodyMode.doorwayStretch:
        return FigureRig(
          torsoAngle: phase * 0.12,
          armUpper: 0.125,
          armLower: 0.12,
          shoulderWidth: 0.06,
          armOut: 1.7 + phase * 0.12,
          armBend: 0.2,
        );

      case BodyMode.deskPushUp:
        return FigureRig(
          hip: const Offset(0.3, 0.68),
          torsoAngle: 0.75 + phase * 0.14,
          legL: Limb.aim(pi + 0.04),
          legR: Limb.aim(pi + 0.14),
          armL: Limb.aim(1.66, bend: 0.1 + phase * 0.5),
          armR: Limb.aim(1.74, bend: 0.12 + phase * 0.5),
        );

      // Seen from the side, facing right: the heel folds up behind, which
      // only reads if the shin swings backward rather than forward.
      case BodyMode.quadStretch:
        return FigureRig(
          hip: const Offset(0.46, 0.66),
          legL: Limb.aim(pi - 0.05),
          legR: Limb.aim(pi + 0.12, bend: 2.15 + phase * 0.3),
          armR: Limb.aim(pi + 0.45, bend: 0.5 + phase * 0.15),
          armL: Limb.open(leftSide, 1.35, bend: 0.2),
        );

      case BodyMode.hamstringStretch:
        return FigureRig(
          hip: const Offset(0.44, 0.62),
          torsoAngle: 0.3 + phase * 0.5,
          legR: Limb.aim(pi - 0.48),
          legL: Limb.aim(pi + 0.14, bend: -0.16),
          armL: Limb.aim(pi - 0.5),
          armR: Limb.aim(pi - 0.62),
        );

      case BodyMode.balance:
        return FigureRig(
          torsoAngle: wave * 0.06,
          legL: Limb.aim(pi + 0.03),
          legR: Limb.aim(pi - 1.1, bend: 1.3),
          armOut: 1.5 + wave * 0.18,
        );

      case BodyMode.hipCircles:
        return FigureRig(
          hip: Offset(0.5 + 0.045 * sin(sweep), 0.68 + 0.018 * cos(sweep)),
          torsoAngle: -0.09 * sin(sweep),
          armOut: 0.8,
          armBend: -1.35,
          legOut: 0.16,
        );

      case BodyMode.heelToeWalk:
        return FigureRig(
          legR: Limb.aim(pi - 0.1 - phase * 0.22),
          legL: Limb.aim(pi + 0.06 + phase * 0.12),
          armOut: 1.5,
          armBend: 0.1,
        );

      case BodyMode.wallSit:
        // A held position with nothing moving reads as a still image, so the
        // only animation is the tremble that actually happens.
        return FigureRig(
          hip: Offset(0.4, 0.68 + 0.004 * sin(t * 16 * pi)),
          legLower: 0.2,
          legL: Limb.aim(pi / 2 + 0.05, bend: pi / 2 - 0.05),
          legR: Limb.aim(pi / 2 - 0.05, bend: pi / 2 + 0.05),
          armL: Limb.aim(pi / 2 - 0.08),
          armR: Limb.aim(pi / 2 + 0.02),
        );

      case BodyMode.buttKicks:
        final right = max(0.0, wave);
        final left = max(0.0, -wave);
        return FigureRig(
          hip: Offset(0.5, 0.66 - max(right, left) * 0.012),
          legR: Limb.aim(pi + 0.08, bend: -right * 2.3),
          legL: Limb.aim(pi - 0.08, bend: left * 2.3),
          armR: Limb.open(rightSide, 0.85, bend: -1.1),
          armL: Limb.open(leftSide, 0.85, bend: -1.1),
        );

      case BodyMode.shadowBox:
        final right = max(0.0, wave);
        final left = max(0.0, -wave);
        return FigureRig(
          torsoAngle: wave * 0.1,
          legR: Limb.aim(pi - 0.28),
          legL: Limb.aim(pi + 0.16, bend: -0.1),
          armR: Limb.open(
            rightSide,
            1.0 + right * 0.6,
            bend: 1.3 - right * 1.3,
          ),
          armL: Limb.open(leftSide, 1.0 + left * 0.6, bend: 1.3 - left * 1.3),
        );

      case BodyMode.jumpRope:
        final hop = max(0.0, sin(t * 4 * pi));
        return FigureRig(
          hip: Offset(0.5, 0.68 - hop * 0.05),
          legOut: 0.07,
          legBend: -0.05 - hop * 0.25,
          armOut: 0.95,
          armBend: -0.95,
        );
    }
  }

  /// Sitting on a chair: thigh out, shin down. Both legs unless a mode
  /// replaces one.
  FigureRig _seated({Limb? legR, double? legLower}) => FigureRig(
    hip: const Offset(0.4, 0.6),
    legLower: legLower ?? 0.135,
    legL: Limb.aim(pi / 2 - 0.06, bend: pi / 2 + 0.06),
    legR: legR ?? Limb.aim(pi / 2 + 0.04, bend: pi / 2 - 0.04),
    armOut: 0.22,
    armBend: 0.5,
  );

  /// Anything drawn from solved joint positions: a rope in the hands, a
  /// guide circle at a foot, toes on the floor.
  void _extrasFor(
    BodyMode mode,
    Canvas canvas,
    Size size,
    FigurePoints p,
    Paint prop,
    double phase,
    double sweep,
  ) {
    final u = size.shortestSide;
    switch (mode) {
      case BodyMode.calfRaise:
        final toes = size.height * 0.95;
        for (final foot in [p.footL, p.footR]) {
          canvas.drawLine(foot, Offset(foot.dx + u * 0.07, toes), prop);
        }

      case BodyMode.ankleCircles:
        canvas.drawOval(
          Rect.fromCenter(
            center: p.footR + Offset(0, u * 0.01),
            width: u * 0.13,
            height: u * 0.07,
          ),
          prop,
        );

      // The rope passes under the feet at the top of the hop and over the
      // head between hops, which is what makes the hop read as skipping.
      case BodyMode.jumpRope:
        final low = sin(sweep * 2) > 0;
        final control = low
            ? Offset((p.footL.dx + p.footR.dx) / 2, p.footL.dy + u * 0.07)
            : Offset(p.head.dx, p.head.dy - u * 0.22);
        canvas.drawPath(
          Path()
            ..moveTo(p.handL.dx, p.handL.dy)
            ..quadraticBezierTo(control.dx, control.dy, p.handR.dx, p.handR.dy),
          prop,
        );

      case _:
        break;
    }
  }

  @override
  bool shouldRepaint(BodyArtPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.mode != mode ||
      oldDelegate.scheme != scheme;
}
