import 'dart:math';

import 'package:flutter/material.dart';

/// Which body animation to draw.
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
}

/// A friendly round-headed figure animating the given exercise.
/// Driven by [t] in [0,1) looping.
class BodyArtPainter extends CustomPainter {
  BodyArtPainter({required this.t, required this.mode, required this.scheme});

  final double t;
  final BodyMode mode;
  final ColorScheme scheme;

  late final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = scheme.primary;

  @override
  void paint(Canvas canvas, Size size) {
    _stroke.strokeWidth = size.shortestSide * 0.045;
    final u = size.shortestSide; // unit
    final cx = size.width / 2;
    final wave = sin(t * 2 * pi); // -1..1

    switch (mode) {
      case BodyMode.breathe:
        final breath = 0.7 + 0.3 * ((wave + 1) / 2);
        for (var i = 3; i >= 1; i--) {
          canvas.drawCircle(
            Offset(cx, size.height / 2),
            u * 0.14 * i * breath,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = _stroke.strokeWidth
              ..color = scheme.primary.withValues(alpha: 0.25 + 0.25 * i / 3),
          );
        }

      case BodyMode.headRoll:
        final lean = wave * 0.5; // radians
        _figure(canvas, size, headOffset: Offset(sin(lean) * u * 0.12, 0));

      case BodyMode.chinTuck:
        final tuck = (wave + 1) / 2; // 0 forward, 1 tucked
        _figure(canvas, size, headOffset: Offset(u * 0.1 - tuck * u * 0.14, 0));

      case BodyMode.shoulders:
        final lift = ((wave + 1) / 2) * u * 0.06;
        _figure(canvas, size, shoulderLift: lift);

      case BodyMode.wrists:
        _figure(canvas, size, armAngle: 0.0, forearmFlex: wave * 0.7);

      case BodyMode.posture:
        final straighten = (wave + 1) / 2; // 0 slouch, 1 tall
        _figure(canvas, size, slouch: 1 - straighten);

      case BodyMode.sideStretch:
        final lean = wave * 0.35;
        _figure(canvas, size, lean: lean, armRaised: true);

      case BodyMode.walk:
        final step = wave;
        _figure(canvas, size, legSwing: step, armAngle: -step * 0.5);

      case BodyMode.neckTilt:
        // Ear toward the shoulder: the head travels sideways and tips with
        // it, unlike headRoll which only translates.
        final tilt = wave * 0.45;
        _figure(
          canvas,
          size,
          headOffset: Offset(sin(tilt) * u * 0.16, u * 0.02),
          headTilt: tilt,
        );

      case BodyMode.chestOpen:
        final open = (wave + 1) / 2;
        _figure(canvas, size, armsBack: open);

      case BodyMode.torsoTwist:
        _figure(canvas, size, twist: wave * 0.8);

      case BodyMode.forwardFold:
        final fold = (wave + 1) / 2;
        _figure(canvas, size, fold: fold, armAngle: 0.2);

      case BodyMode.calfRaise:
        _figure(canvas, size, heelLift: (wave + 1) / 2);

      case BodyMode.armCircles:
        _figure(canvas, size, armSweep: t * 2 * pi);

      case BodyMode.squat:
        _figure(canvas, size, legBend: (wave + 1) / 2, armAngle: -0.4);

      case BodyMode.lunge:
        _figure(
          canvas,
          size,
          legBend: (wave + 1) / 2,
          stagger: wave.sign * 0.8,
        );

      case BodyMode.marchInPlace:
        _figure(canvas, size, kneeLift: wave, armAngle: -wave * 0.7);

      case BodyMode.jumpingJacks:
        final open = (wave + 1) / 2;
        _figure(canvas, size, stance: open, armsUp: open);
    }
  }

  /// Draws the figure: head, spine, arms, legs — pose set by parameters.
  void _figure(
    Canvas canvas,
    Size size, {
    Offset headOffset = Offset.zero,
    double shoulderLift = 0,
    double slouch = 0,
    double lean = 0,
    double legSwing = 0,
    double armAngle = 0.6,
    double forearmFlex = 0,
    bool armRaised = false,
    double headTilt = 0,
    double armsBack = 0,
    double twist = 0,
    double fold = 0,
    double heelLift = 0,
    double? armSweep,
    double legBend = 0,
    double stagger = 0,
    double kneeLift = 0,
    double stance = 0,
    double armsUp = 0,
  }) {
    final u = size.shortestSide;
    final cx = size.width / 2;
    final legLen = u * 0.2;
    // Bending the knees drops the hips and shortens the visible leg; lifting
    // the heels raises the whole figure. Both move the same anchor, so they
    // are resolved here rather than in each mode.
    final hipY =
        size.height * 0.78 + legBend * legLen * 0.55 - heelLift * u * 0.05;
    final hip = Offset(cx, hipY);

    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(lean);
    canvas.translate(-hip.dx, -hip.dy);

    // Spine: curved when slouching, straight when tall. Folding at the hip
    // pitches the whole upper body forward, so the shoulder swings out and
    // down along an arc rather than simply sinking.
    final foldAngle = fold * 1.15; // up to ~66 degrees
    final spineLen = u * 0.34;
    final shoulderY =
        hipY - cos(foldAngle) * spineLen + slouch * u * 0.05 - shoulderLift;
    final shoulder = Offset(
      cx + slouch * u * 0.06 + sin(foldAngle) * spineLen,
      shoulderY,
    );
    final spine = Path()
      ..moveTo(hip.dx, hip.dy)
      ..quadraticBezierTo(
        cx + slouch * u * 0.14,
        (hipY + shoulderY) / 2,
        shoulder.dx,
        shoulder.dy,
      );
    canvas.drawPath(spine, _stroke);

    // Head.
    // The head follows the fold and can tip independently (neck tilt).
    final headDir = foldAngle + headTilt;
    final head =
        shoulder +
        Offset(
          headOffset.dx + slouch * u * 0.08 + sin(headDir) * u * 0.13,
          headOffset.dy - cos(headDir) * u * 0.13,
        );
    canvas.drawCircle(head, u * 0.09, _stroke);

    // Arms.
    final armLen = u * 0.22;
    if (armSweep != null) {
      // Both arms out to the sides, tracing circles from the shoulder.
      for (final side in [-1.0, 1.0]) {
        final hand =
            shoulder +
            Offset(
              side * armLen * (0.9 + 0.25 * cos(armSweep)),
              armLen * 0.25 * sin(armSweep),
            );
        canvas.drawLine(shoulder, hand, _stroke);
      }
    } else if (armsUp > 0) {
      // Jumping jack: arms sweep from low at the sides up into a wide star.
      //
      // Two constraints, both learned by looking at the render. The angle
      // stays inside ±pi/2 so cos never goes negative — past vertical each
      // arm crossed the centre line and drew straight through the head. And
      // it peaks at ~43 degrees rather than overhead, which keeps the arms
      // clear of the head circle while still reading as the top of a jack.
      final angle = -0.9 + armsUp * 1.65;
      for (final side in [-1.0, 1.0]) {
        // Arms hang from the ends of the shoulders, not from the neck.
        final root = shoulder + Offset(side * u * 0.06, 0);
        canvas.drawLine(
          root,
          root + Offset(side * cos(angle) * armLen, -sin(angle) * armLen),
          _stroke,
        );
      }
    } else if (armsBack > 0) {
      // Chest opener: hands clasped low behind the back.
      for (final side in [-1.0, 1.0]) {
        canvas.drawLine(
          shoulder,
          shoulder +
              Offset(
                side * armLen * (0.5 - armsBack * 0.35),
                armLen * (0.75 + armsBack * 0.2),
              ),
          _stroke,
        );
      }
    } else if (armRaised) {
      // One arm overhead following the lean, one resting.
      canvas.drawLine(
        shoulder,
        shoulder + Offset(-armLen * 0.7, armLen * 0.6),
        _stroke,
      );
      canvas.drawLine(
        shoulder,
        shoulder + Offset(armLen * 0.35, -armLen),
        _stroke,
      );
    } else {
      final elbow =
          shoulder +
          Offset(
            armLen * 0.8 + twist * armLen * 0.5,
            armLen * (0.5 + armAngle * 0.3),
          );
      canvas.drawLine(shoulder, elbow, _stroke);
      // Forearm/hand, flexing at the elbow for the wrist exercise.
      final hand =
          elbow + Offset.fromDirection(-0.4 + forearmFlex, armLen * 0.8);
      canvas.drawLine(elbow, hand, _stroke);
      canvas.drawLine(
        shoulder,
        shoulder +
            Offset(
              -armLen * 0.8 + twist * armLen * 0.5,
              armLen * (0.5 - armAngle * 0.3),
            ),
        _stroke,
      );
    }

    // Legs. Knees are drawn explicitly whenever the figure bends, so a squat
    // reads as a squat rather than as a figure that simply shrank.
    final spread = legLen * (0.25 + stance * 0.7);
    for (final side in [1.0, -1.0]) {
      final swing = side * legSwing * legLen * 0.6;
      final lift = side > 0 ? max(0.0, kneeLift) : max(0.0, -kneeLift);
      final footY = hip.dy + legLen * (1 - lift * 0.45);
      final foot = Offset(
        hip.dx + swing + side * spread + side * stagger * legLen * 0.5,
        footY,
      );
      if (legBend > 0 || lift > 0) {
        final knee = Offset(
          (hip.dx + foot.dx) / 2 + side * legLen * (0.3 * legBend + 0.2 * lift),
          hip.dy + legLen * 0.5 * (1 - lift * 0.5),
        );
        canvas
          ..drawLine(hip, knee, _stroke)
          ..drawLine(knee, foot, _stroke);
      } else {
        canvas.drawLine(hip, foot, _stroke);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(BodyArtPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mode != mode;
}
