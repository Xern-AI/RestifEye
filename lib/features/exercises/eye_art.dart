// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

/// Which eye animation to draw.
enum EyeMode { farNear, palming, figureEight, blink }

/// A pair of cartoon eyes animating the given exercise. Driven by [t] in
/// [0,1) looping.
class EyeArtPainter extends CustomPainter {
  EyeArtPainter({required this.t, required this.mode, required this.scheme});

  final double t;
  final EyeMode mode;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035
      ..strokeCap = StrokeCap.round
      ..color = scheme.primary;
    final fill = Paint()..color = scheme.primary;
    final accent = Paint()..color = scheme.tertiary;

    final eyeRadius = size.shortestSide * 0.16;
    final leftCenter = Offset(size.width * 0.32, size.height * 0.45);
    final rightCenter = Offset(size.width * 0.68, size.height * 0.45);

    switch (mode) {
      case EyeMode.blink:
        // Two quick blinks then a rest, per loop.
        final phase = t * 2 % 1;
        final closed = phase < 0.15 || (phase > 0.3 && phase < 0.45);
        for (final c in [leftCenter, rightCenter]) {
          if (closed) {
            canvas.drawLine(
              c - Offset(eyeRadius, 0),
              c + Offset(eyeRadius, 0),
              stroke,
            );
          } else {
            canvas.drawCircle(c, eyeRadius, stroke);
            canvas.drawCircle(c, eyeRadius * 0.4, fill);
          }
        }

      case EyeMode.palming:
        // Gently breathing ring behind two peacefully closed eyes.
        final breath = 0.85 + 0.15 * sin(t * 2 * pi);
        canvas.drawCircle(
          Offset(size.width / 2, size.height * 0.45),
          size.shortestSide * 0.42 * breath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.strokeWidth
            ..color = scheme.tertiary.withValues(alpha: 0.5),
        );
        for (final c in [leftCenter, rightCenter]) {
          final rect = Rect.fromCircle(center: c, radius: eyeRadius);
          canvas.drawArc(rect, pi * 0.15, pi * 0.7, false, stroke);
        }

      case EyeMode.farNear:
        // Pupils shrink while a target dot drifts away, then return.
        final phase = (sin(t * 2 * pi) + 1) / 2; // 0 near, 1 far
        final pupil = eyeRadius * (0.55 - 0.3 * phase);
        for (final c in [leftCenter, rightCenter]) {
          canvas.drawCircle(c, eyeRadius, stroke);
          canvas.drawCircle(c, pupil, fill);
        }
        final target = Offset(
          size.width / 2,
          size.height * (0.82 - 0.55 * phase),
        );
        canvas.drawCircle(
          target,
          size.shortestSide * (0.05 - 0.03 * phase),
          accent,
        );

      case EyeMode.figureEight:
        // Pupils trace a sideways 8 together.
        final angle = t * 2 * pi;
        final wander = Offset(
          sin(angle) * eyeRadius * 0.45,
          sin(2 * angle) * eyeRadius * 0.3,
        );
        for (final c in [leftCenter, rightCenter]) {
          canvas.drawCircle(c, eyeRadius, stroke);
          canvas.drawCircle(c + wander, eyeRadius * 0.4, fill);
        }
        // Faint 8 path below as a guide.
        final path = Path();
        final guide = Offset(size.width / 2, size.height * 0.82);
        final gw = size.width * 0.18;
        final gh = size.height * 0.06;
        for (var i = 0; i <= 64; i++) {
          final a = i / 64 * 2 * pi;
          final p = guide + Offset(sin(a) * gw, sin(2 * a) * gh);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.strokeWidth * 0.6
            ..color = scheme.tertiary.withValues(alpha: 0.6),
        );
    }
  }

  @override
  bool shouldRepaint(EyeArtPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mode != mode;
}
