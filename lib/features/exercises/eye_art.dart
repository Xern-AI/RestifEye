// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

/// Which eye animation to draw.
enum EyeMode {
  farNear,
  palming,
  figureEight,
  blink,
  roll,
  scan,
  diagonal,
  zoom,
  squeeze,
  massage,
}

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
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke.strokeWidth * 0.6
      ..strokeCap = StrokeCap.round
      ..color = scheme.tertiary.withValues(alpha: 0.6);

    final r = size.shortestSide * 0.16;
    final leftCenter = Offset(size.width * 0.32, size.height * 0.45);
    final rightCenter = Offset(size.width * 0.68, size.height * 0.45);
    final centers = [leftCenter, rightCenter];
    final guideAt = Offset(size.width / 2, size.height * 0.82);

    /// One open eye with its pupil displaced by [look].
    void open(Offset c, {Offset look = Offset.zero, double pupil = 0.4}) {
      canvas
        ..drawCircle(c, r, stroke)
        ..drawCircle(c + look, r * pupil, fill);
    }

    void shut(Offset c) => canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      pi * 0.15,
      pi * 0.7,
      false,
      stroke,
    );

    switch (mode) {
      case EyeMode.blink:
        // Two quick blinks then a rest, per loop.
        final phase = t * 2 % 1;
        final closed = phase < 0.15 || (phase > 0.3 && phase < 0.45);
        for (final c in centers) {
          if (closed) {
            canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), stroke);
          } else {
            open(c);
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
        for (final c in centers) {
          shut(c);
        }

      case EyeMode.farNear:
        // Pupils shrink while a target dot drifts away, then return.
        final phase = (sin(t * 2 * pi) + 1) / 2; // 0 near, 1 far
        for (final c in centers) {
          open(c, pupil: 0.55 - 0.3 * phase);
        }
        canvas.drawCircle(
          Offset(size.width / 2, size.height * (0.82 - 0.55 * phase)),
          size.shortestSide * (0.05 - 0.03 * phase),
          accent,
        );

      case EyeMode.figureEight:
        // Pupils trace a sideways 8 together.
        final angle = t * 2 * pi;
        final look = Offset(sin(angle) * r * 0.45, sin(2 * angle) * r * 0.3);
        for (final c in centers) {
          open(c, look: look);
        }
        _trace(
          canvas,
          guide,
          guideAt,
          (a) => Offset(
            sin(a) * size.width * 0.18,
            sin(2 * a) * size.height * 0.06,
          ),
        );

      // ---- added -------------------------------------------------------
      case EyeMode.roll:
        final angle = t * 2 * pi;
        final look = Offset(sin(angle), -cos(angle)) * (r * 0.45);
        for (final c in centers) {
          open(c, look: look);
        }
        _trace(
          canvas,
          guide,
          guideAt,
          (a) =>
              Offset(sin(a) * size.width * 0.1, -cos(a) * size.height * 0.07),
        );
        // The leading dot says which way round, which the pupils alone
        // cannot: a circle looks the same in both directions.
        canvas.drawCircle(
          guideAt +
              Offset(
                sin(angle) * size.width * 0.1,
                -cos(angle) * size.height * 0.07,
              ),
          size.shortestSide * 0.022,
          accent,
        );

      // Up and down for the first half of the loop, side to side for the
      // second, with the guide showing which axis is live.
      case EyeMode.scan:
        final vertical = t < 0.5;
        final s = (t % 0.5) * 4 * pi;
        final look = vertical
            ? Offset(0, -cos(s) * r * 0.5)
            : Offset(sin(s) * r * 0.5, 0);
        for (final c in centers) {
          open(c, look: look);
        }
        _axis(canvas, guide, accent, guideAt, size, vertical);

      case EyeMode.diagonal:
        final first = t < 0.5;
        final s = (t % 0.5) * 4 * pi;
        final axis = first
            ? const Offset(0.707, -0.707)
            : const Offset(-0.707, -0.707);
        final look = axis * (sin(s) * r * 0.5);
        for (final c in centers) {
          open(c, look: look);
        }
        final reach = Offset(size.width * 0.12, size.height * 0.08);
        for (final d in [
          const Offset(0.707, -0.707),
          const Offset(-0.707, -0.707),
        ]) {
          final live = d == axis;
          canvas.drawLine(
            guideAt - Offset(d.dx * reach.dx, d.dy * reach.dy),
            guideAt + Offset(d.dx * reach.dx, d.dy * reach.dy),
            live ? (Paint.from(guide)..color = accent.color) : guide,
          );
        }

      // Thumb up close, then something far behind it. The pupils converge
      // on the near target and relax on the far one.
      case EyeMode.zoom:
        final phase = (sin(t * 2 * pi) + 1) / 2; // 0 thumb, 1 far
        final converge = (1 - phase) * r * 0.28;
        open(leftCenter, look: Offset(converge, 0), pupil: 0.55 - 0.2 * phase);
        open(
          rightCenter,
          look: Offset(-converge, 0),
          pupil: 0.55 - 0.2 * phase,
        );
        final thumb = Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.85),
          width: size.shortestSide * 0.13,
          height: size.shortestSide * 0.24,
        );
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              thumb,
              Radius.circular(size.shortestSide * 0.065),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke.strokeWidth * 0.9
              ..color = scheme.tertiary.withValues(
                alpha: 0.3 + 0.7 * (1 - phase),
              ),
          )
          ..drawCircle(
            Offset(size.width / 2, size.height * 0.66),
            size.shortestSide * 0.022,
            Paint()
              ..color = scheme.tertiary.withValues(alpha: 0.2 + 0.8 * phase),
          );

      // Screwed shut, then opened wider than normal — the brows are what
      // make the second half read as "wide" rather than just "open".
      case EyeMode.squeeze:
        final tight = t < 0.45;
        for (final (i, c) in centers.indexed) {
          // Crow's feet belong on the outside of each eye, not between them.
          final outward = i == 0 ? -1.0 : 1.0;
          if (tight) {
            canvas.drawArc(
              Rect.fromCircle(center: c, radius: r * 0.9),
              pi * 1.15,
              pi * 0.7,
              false,
              stroke,
            );
            for (var line = -1; line <= 1; line++) {
              final from = c + Offset(outward * r, r * 0.28 * line);
              canvas.drawLine(
                from,
                from + Offset(outward * r * 0.34, 0),
                guide,
              );
            }
          } else {
            final grow = 1 + 0.16 * sin((t - 0.45) / 0.55 * pi);
            canvas
              ..drawCircle(c, r * grow, stroke)
              ..drawCircle(c, r * 0.34, fill)
              ..drawArc(
                Rect.fromCircle(center: c, radius: r * 1.5),
                pi * 1.2,
                pi * 0.6,
                false,
                guide,
              );
          }
        }

      case EyeMode.massage:
        for (final c in centers) {
          shut(c);
        }
        final angle = t * 2 * pi;
        for (final side in [-1.0, 1.0]) {
          final temple = Offset(
            size.width * (0.5 + side * 0.37),
            size.height * 0.45,
          );
          final orbit = Offset(sin(angle) * side, -cos(angle)) * (r * 0.3);
          canvas
            ..drawCircle(temple, r * 0.3, guide)
            ..drawCircle(temple + orbit, size.shortestSide * 0.038, accent);
        }
    }
  }

  /// Draws a closed parametric guide path below the eyes.
  void _trace(
    Canvas canvas,
    Paint paint,
    Offset origin,
    Offset Function(double angle) at,
  ) {
    final path = Path();
    for (var i = 0; i <= 64; i++) {
      final p = origin + at(i / 64 * 2 * pi);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  /// A plus-shaped guide with the live axis picked out.
  void _axis(
    Canvas canvas,
    Paint guide,
    Paint accent,
    Offset origin,
    Size size,
    bool vertical,
  ) {
    final live = Paint.from(guide)..color = accent.color;
    canvas
      ..drawLine(
        origin - Offset(size.width * 0.14, 0),
        origin + Offset(size.width * 0.14, 0),
        vertical ? guide : live,
      )
      ..drawLine(
        origin - Offset(0, size.height * 0.09),
        origin + Offset(0, size.height * 0.09),
        vertical ? live : guide,
      );
  }

  @override
  bool shouldRepaint(EyeArtPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.mode != mode ||
      oldDelegate.scheme != scheme;
}
