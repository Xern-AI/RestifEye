// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

/// Screen direction for an angle measured from straight up, turning
/// clockwise: 0 is up, pi/2 is right, pi is down, -pi/2 is left.
Offset dirOf(double angle) => Offset(sin(angle), -cos(angle));

const double leftSide = -1;
const double rightSide = 1;

/// One arm or leg: the screen angles of its two segments.
class Limb {
  const Limb._(this.upper, this.lower, this.followsTorso);

  /// A limb opened away from the body. [outward] is 0 hanging straight down,
  /// pi/2 straight out to the side and pi overhead; [side] mirrors it, so a
  /// single number poses both sides symmetrically. [bend] folds the lower
  /// segment in the same handed direction.
  factory Limb.open(double side, double outward, {double bend = 0}) {
    final upper = pi - side * outward;
    return Limb._(upper, upper - side * bend, true);
  }

  /// A limb pointed at an absolute screen angle. Used where gravity rather
  /// than anatomy decides the direction — arms hanging from a folded torso,
  /// or a hand reaching for a fixed prop.
  factory Limb.aim(double angle, {double bend = 0}) =>
      Limb._(angle, angle + bend, false);

  final double upper;
  final double lower;

  /// Whether the angles are measured from the trunk or from the screen.
  /// Only consulted for arms — legs are always measured against the screen.
  final bool followsTorso;
}

/// Every joint of a posed figure, in canvas pixels.
typedef FigurePoints = ({
  Offset hip,
  Offset neck,
  Offset head,
  Offset shoulderL,
  Offset shoulderR,
  Offset elbowL,
  Offset handL,
  Offset elbowR,
  Offset handR,
  Offset kneeL,
  Offset footL,
  Offset kneeR,
  Offset footR,
  double headRadius,
});

/// A jointed stick figure posed by angles rather than by ad-hoc offsets.
///
/// Positions are fractions of the canvas box and lengths fractions of its
/// shortest side, so one pose renders identically at any size.
///
/// Arm angles are measured from the trunk, because an arm belongs to the
/// torso and should follow it when it leans. Leg angles are measured against
/// the screen, because feet stay on the floor whatever the trunk does. Where
/// an arm needs the other rule — hanging toward the floor from a folded
/// spine — [Limb.aim] opts out.
class FigureRig {
  FigureRig({
    this.hip = const Offset(0.5, 0.68),
    this.torsoAngle = 0,
    this.torsoBend = 0,
    this.torso = 0.28,
    this.headTilt = 0,
    this.headShift = Offset.zero,
    this.headRadius = 0.075,
    this.shoulderLift = 0,
    this.shoulderWidth = 0.05,
    this.hipWidth = 0.035,
    this.armUpper = 0.115,
    this.armLower = 0.105,
    this.legUpper = 0.135,
    this.legLower = 0.135,
    double armOut = 0.22,
    double armBend = 0.12,
    double legOut = 0.11,
    double legBend = 0,
    Limb? armL,
    Limb? armR,
    Limb? legL,
    Limb? legR,
  }) : armL = armL ?? Limb.open(leftSide, armOut, bend: armBend),
       armR = armR ?? Limb.open(rightSide, armOut, bend: armBend),
       legL = legL ?? Limb.open(leftSide, legOut, bend: legBend),
       legR = legR ?? Limb.open(rightSide, legOut, bend: legBend);

  /// Hip centre, as a fraction of the canvas box.
  final Offset hip;

  /// Trunk lean: 0 upright, pi/2 horizontal to the right.
  final double torsoAngle;

  /// Sideways bow of the spine, as a fraction of its length. Positive bows
  /// toward the figure's right.
  final double torsoBend;

  final double torso;
  final double headTilt;

  /// Extra head displacement in units, after the neck has placed it.
  final Offset headShift;

  final double headRadius;
  final double shoulderLift;
  final double shoulderWidth;
  final double hipWidth;
  final double armUpper;
  final double armLower;
  final double legUpper;
  final double legLower;

  final Limb armL;
  final Limb armR;
  final Limb legL;
  final Limb legR;

  FigurePoints solve(Size size) {
    final u = size.shortestSide;
    final hipP = Offset(hip.dx * size.width, hip.dy * size.height);
    final up = dirOf(torsoAngle);
    final across = dirOf(torsoAngle + pi / 2);

    final neck = hipP + up * (torso * u);
    final rise = up * (shoulderLift * u);
    final shoulderR = neck + across * (shoulderWidth * u) + rise;
    final shoulderL = neck - across * (shoulderWidth * u) + rise;
    final hipR = hipP + across * (hipWidth * u);
    final hipL = hipP - across * (hipWidth * u);

    final head =
        neck +
        dirOf(torsoAngle + headTilt) * ((headRadius + 0.035) * u) +
        headShift * u;

    (Offset, Offset) chain(
      Offset root,
      Limb limb,
      double upperLen,
      double lowerLen,
      double base,
    ) {
      final joint = root + dirOf(base + limb.upper) * upperLen;
      return (joint, joint + dirOf(base + limb.lower) * lowerLen);
    }

    final armBase = torsoAngle;
    final (elbowL, handL) = chain(
      shoulderL,
      armL,
      armUpper * u,
      armLower * u,
      armL.followsTorso ? armBase : 0,
    );
    final (elbowR, handR) = chain(
      shoulderR,
      armR,
      armUpper * u,
      armLower * u,
      armR.followsTorso ? armBase : 0,
    );
    final (kneeL, footL) = chain(hipL, legL, legUpper * u, legLower * u, 0);
    final (kneeR, footR) = chain(hipR, legR, legUpper * u, legLower * u, 0);

    return (
      hip: hipP,
      neck: neck,
      head: head,
      shoulderL: shoulderL,
      shoulderR: shoulderR,
      elbowL: elbowL,
      handL: handL,
      elbowR: elbowR,
      handR: handR,
      kneeL: kneeL,
      footL: footL,
      kneeR: kneeR,
      footR: footR,
      headRadius: headRadius * u,
    );
  }

  void paint(Canvas canvas, Size size, Paint stroke, [FigurePoints? solved]) {
    final p = solved ?? solve(size);
    final u = size.shortestSide;
    final across = dirOf(torsoAngle + pi / 2);

    final mid = (p.hip + p.neck) / 2 + across * (torsoBend * torso * u);
    canvas.drawPath(
      Path()
        ..moveTo(p.hip.dx, p.hip.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p.neck.dx, p.neck.dy),
      stroke,
    );

    final hipR = p.hip + across * (hipWidth * u);
    final hipL = p.hip - across * (hipWidth * u);
    canvas
      ..drawLine(p.shoulderL, p.shoulderR, stroke)
      ..drawLine(hipL, hipR, stroke)
      ..drawCircle(p.head, p.headRadius, stroke)
      ..drawLine(p.shoulderL, p.elbowL, stroke)
      ..drawLine(p.elbowL, p.handL, stroke)
      ..drawLine(p.shoulderR, p.elbowR, stroke)
      ..drawLine(p.elbowR, p.handR, stroke)
      ..drawLine(hipL, p.kneeL, stroke)
      ..drawLine(p.kneeL, p.footL, stroke)
      ..drawLine(hipR, p.kneeR, stroke)
      ..drawLine(p.kneeR, p.footR, stroke);
  }
}

/// Shared props. Drawn behind the figure in a lighter weight so the body
/// always reads as the subject and the furniture as context.
class ArtProps {
  const ArtProps(this.canvas, this.size, this.paint);

  final Canvas canvas;
  final Size size;
  final Paint paint;

  void floor(double y) => canvas.drawLine(
    Offset(size.width * 0.08, size.height * y),
    Offset(size.width * 0.92, size.height * y),
    paint,
  );

  /// A vertical surface with hatching on its far side, so it reads as a wall
  /// rather than as a stray line.
  void wall(double x) {
    final top = size.height * 0.1;
    final bottom = size.height * 0.94;
    final px = size.width * x;
    canvas.drawLine(Offset(px, top), Offset(px, bottom), paint);
    final step = (bottom - top) / 9;
    for (var y = top; y < bottom - step * 0.4; y += step) {
      canvas.drawLine(
        Offset(px, y + step * 0.5),
        Offset(px - step * 0.45, y),
        paint,
      );
    }
  }

  /// A horizontal surface starting at [x] and running to the right edge.
  void ledge(double x, double y) {
    final py = size.height * y;
    canvas
      ..drawLine(
        Offset(size.width * x, py),
        Offset(size.width * 0.95, py),
        paint,
      )
      ..drawLine(
        Offset(size.width * (x + 0.06), py),
        Offset(size.width * (x + 0.06), size.height * 0.92),
        paint,
      );
  }

  void doorway() {
    final top = size.height * 0.12;
    final bottom = size.height * 0.94;
    for (final x in [size.width * 0.18, size.width * 0.82]) {
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    canvas.drawLine(
      Offset(size.width * 0.18, top),
      Offset(size.width * 0.82, top),
      paint,
    );
  }

  /// A chair seen from the side, with its seat at [seatY] and its back
  /// behind [seatX] — where a seated figure's hips go.
  void chair(double seatX, double seatY) {
    final sx = size.width * seatX;
    final sy = size.height * seatY;
    final back = sx - size.width * 0.1;
    final front = sx + size.width * 0.16;
    final floor = size.height * 0.93;
    canvas
      ..drawLine(Offset(back, sy), Offset(front, sy), paint)
      ..drawLine(Offset(back, sy), Offset(back, sy - size.height * 0.26), paint)
      ..drawLine(Offset(back, sy), Offset(back, floor), paint)
      ..drawLine(Offset(front, sy), Offset(front, floor), paint);
  }
}
