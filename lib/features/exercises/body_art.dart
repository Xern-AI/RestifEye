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
  }) {
    final u = size.shortestSide;
    final cx = size.width / 2;
    final hipY = size.height * 0.78;
    final hip = Offset(cx, hipY);

    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(lean);
    canvas.translate(-hip.dx, -hip.dy);

    // Spine: curved when slouching, straight when tall.
    final shoulderY = hipY - u * 0.34 + slouch * u * 0.05 - shoulderLift;
    final shoulder = Offset(cx + slouch * u * 0.06, shoulderY);
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
    final head =
        shoulder +
        Offset(headOffset.dx + slouch * u * 0.08, -u * 0.13 + headOffset.dy);
    canvas.drawCircle(head, u * 0.09, _stroke);

    // Arms.
    final armLen = u * 0.22;
    if (armRaised) {
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
          shoulder + Offset(armLen * 0.8, armLen * (0.5 + armAngle * 0.3));
      canvas.drawLine(shoulder, elbow, _stroke);
      // Forearm/hand, flexing at the elbow for the wrist exercise.
      final hand =
          elbow + Offset.fromDirection(-0.4 + forearmFlex, armLen * 0.8);
      canvas.drawLine(elbow, hand, _stroke);
      canvas.drawLine(
        shoulder,
        shoulder + Offset(-armLen * 0.8, armLen * (0.5 - armAngle * 0.3)),
        _stroke,
      );
    }

    // Legs.
    final legLen = u * 0.2;
    canvas.drawLine(
      hip,
      hip + Offset(legSwing * legLen * 0.6 - legLen * 0.25, legLen),
      _stroke,
    );
    canvas.drawLine(
      hip,
      hip + Offset(-legSwing * legLen * 0.6 + legLen * 0.25, legLen),
      _stroke,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(BodyArtPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mode != mode;
}
