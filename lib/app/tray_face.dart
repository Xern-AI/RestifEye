import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../core/mood/mood.dart';
import '../platform/interfaces/tray_indicator.dart';

/// How a mood looks. Colour is never the only difference — every mood also
/// changes the eyes or the mouth, so the indicator still reads for the ~8% of
/// men with a colour vision deficiency, and in the monochrome tray themes
/// some desktops apply.
class MoodFace {
  const MoodFace({
    required this.background,
    required this.eyes,
    required this.mouth,
    required this.tooltip,
  });

  final Color background;
  final TrayEyes eyes;
  final TrayMouth mouth;

  /// Shown on hover. A coloured face with no explanation is just anxiety, so
  /// every mood says in words what it means.
  final String tooltip;

  static const _brand = Color(0xFF00897B);

  static MoodFace of(Mood mood) => switch (mood) {
    Mood.paused => const MoodFace(
      background: Color(0xFF6B7280),
      eyes: TrayEyes.closed,
      mouth: TrayMouth.flat,
      tooltip: 'Paused — breaks are off',
    ),
    Mood.resting => const MoodFace(
      background: Color(0xFF3B82F6),
      eyes: TrayEyes.closed,
      mouth: TrayMouth.smile,
      tooltip: 'Break time — rest your eyes',
    ),
    Mood.great => const MoodFace(
      background: Color(0xFF16A34A),
      eyes: TrayEyes.happy,
      mouth: TrayMouth.grin,
      tooltip: "You're taking your breaks — keep it up",
    ),
    Mood.good => const MoodFace(
      background: _brand,
      eyes: TrayEyes.open,
      mouth: TrayMouth.smile,
      tooltip: 'On schedule',
    ),
    Mood.tired => const MoodFace(
      background: Color(0xFFEA580C),
      eyes: TrayEyes.droopy,
      mouth: TrayMouth.flat,
      tooltip: "That's a long stretch at the screen — take a proper break",
    ),
    Mood.slipping => const MoodFace(
      background: Color(0xFFEAB308),
      eyes: TrayEyes.open,
      mouth: TrayMouth.flat,
      tooltip: 'Breaks are slipping — try taking the next one',
    ),
    Mood.ignoring => const MoodFace(
      background: Color(0xFFDC2626),
      eyes: TrayEyes.open,
      mouth: TrayMouth.frown,
      tooltip: 'Several breaks skipped — your eyes need one',
    ),
  };
}

/// Eye treatments. Public because [MoodFace] exposes them, and because the
/// shape — not just the colour — is what carries the meaning.
enum TrayEyes { open, happy, closed, droopy }

enum TrayMouth { grin, smile, flat, frown }

/// Sizes offered to the host, which picks the closest to its panel height
/// and scales it.
///
/// Only 24 and 48 were offered at first. A GNOME panel asking for 22 or 32
/// then had to rescale, and a rescaled 24 px face is exactly the soft, small
/// smudge that made the icon look shrunken next to its neighbours. Rendering
/// is a few hundred microseconds per size and happens on mood changes, so
/// covering the common panel heights outright is the cheaper trade.
///
/// Starts at 22, not 16: at 16 px the strokes fall below a pixel and the face
/// turns to mush, and a host that naively takes the first entry rather than
/// the best fit would land on exactly that. Every size offered here has to be
/// one we would be happy to see drawn.
const _traySizes = [22, 24, 32, 48, 64];

/// Renders [mood] into the ARGB32 pixmaps the StatusNotifierItem protocol
/// expects, at every size a host might want.
///
/// Drawn at runtime rather than shipped as PNGs: seven moods times two sizes
/// is fourteen assets to keep in sync, and the pulse animation needs
/// in-between frames that could not be pre-rendered sensibly anyway.
Future<List<TrayPixmap>> renderTrayFace(Mood mood, {double scale = 1}) async {
  final face = MoodFace.of(mood);
  final pixmaps = <TrayPixmap>[];
  for (final size in _traySizes) {
    pixmaps.add(await _render(face, size, scale));
  }
  return pixmaps;
}

Future<TrayPixmap> _render(MoodFace face, int size, double scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();

  // The pulse scales the face about its centre. The upper clamp is tied to
  // the inset below: at 1.04 the face exactly fills the pixmap, and anything
  // beyond would clip its rounded corners into a hard square.
  final factor = scale.clamp(0.85, 1.04);
  canvas
    ..translate(s / 2, s / 2)
    ..scale(factor)
    ..translate(-s / 2, -s / 2);

  _paintFace(canvas, face, s);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  final rgba = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();

  return TrayPixmap(
    width: size,
    height: size,
    argb32: _rgbaToArgb32(rgba!.buffer.asUint8List()),
  );
}

void _paintFace(Canvas canvas, MoodFace face, double s) {
  // All geometry is a fraction of the canvas, so every size is the same
  // drawing rather than several hand-tuned ones.
  //
  // Nearly full bleed. The app icon's 6.25% margin is right for a launcher,
  // where the icon sits alone in generous padding, and wrong for a tray,
  // where the host adds its own padding on top — stacking the two is what
  // made this render visibly smaller than every other status icon. 4% is
  // just enough to keep the rounded corners from touching the edge, and
  // leaves the headroom the pulse scales into.
  final inset = s * 0.04;
  final rect = Rect.fromLTWH(inset, inset, s - inset * 2, s - inset * 2);
  final body = Paint()..color = face.background;
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(s * 0.22)),
    body,
  );

  const ink = Color(0xFFFFFFFF);
  final stroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = s * 0.075;
  final fill = Paint()..color = ink;

  final eyeY = s * 0.42;
  final eyeDx = s * 0.15;
  _paintEyes(canvas, face.eyes, s, eyeY, eyeDx, stroke, fill);
  _paintMouth(canvas, face.mouth, s, stroke);
}

void _paintEyes(
  Canvas canvas,
  TrayEyes eyes,
  double s,
  double eyeY,
  double eyeDx,
  Paint stroke,
  Paint fill,
) {
  final centres = [s / 2 - eyeDx, s / 2 + eyeDx];
  switch (eyes) {
    case TrayEyes.open:
      // The app mark's two pause bars, read as eyes — the whole reason this
      // icon can carry an expression at all.
      for (final x in centres) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, eyeY),
              width: s * 0.09,
              height: s * 0.2,
            ),
            Radius.circular(s * 0.045),
          ),
          fill,
        );
      }
    case TrayEyes.happy:
      // Upward arcs: the classic ^^ smiling eyes.
      for (final x in centres) {
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(x, eyeY + s * 0.03),
            width: s * 0.16,
            height: s * 0.16,
          ),
          3.34, // ~191°
          2.5, // sweep across the top
          false,
          stroke,
        );
      }
    case TrayEyes.closed:
      for (final x in centres) {
        canvas.drawLine(
          Offset(x - s * 0.06, eyeY),
          Offset(x + s * 0.06, eyeY),
          stroke,
        );
      }
    case TrayEyes.droopy:
      // Half-lidded: a short bar with a heavy lid over its top half.
      //
      // The lids must be *mirrored*, sloping down toward the outside of the
      // face. Sloping both the same way gives one raised brow and one lowered
      // one, which the eye reads as anger rather than fatigue — and telling a
      // tired user off is the opposite of the point.
      for (var i = 0; i < centres.length; i++) {
        final x = centres[i];
        final outward = i == 0 ? -1.0 : 1.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, eyeY + s * 0.03),
              width: s * 0.09,
              height: s * 0.11,
            ),
            Radius.circular(s * 0.045),
          ),
          fill,
        );
        canvas.drawLine(
          Offset(x + outward * s * 0.085, eyeY - s * 0.015),
          Offset(x - outward * s * 0.085, eyeY - s * 0.065),
          stroke,
        );
      }
  }
}

void _paintMouth(Canvas canvas, TrayMouth mouth, double s, Paint stroke) {
  final centre = Offset(s / 2, s * 0.62);
  switch (mouth) {
    case TrayMouth.grin:
      canvas.drawArc(
        Rect.fromCenter(center: centre, width: s * 0.38, height: s * 0.3),
        0.35,
        2.44,
        false,
        stroke,
      );
    case TrayMouth.smile:
      canvas.drawArc(
        Rect.fromCenter(center: centre, width: s * 0.3, height: s * 0.2),
        0.52,
        2.1,
        false,
        stroke,
      );
    case TrayMouth.flat:
      canvas.drawLine(
        Offset(s / 2 - s * 0.13, centre.dy + s * 0.03),
        Offset(s / 2 + s * 0.13, centre.dy + s * 0.03),
        stroke,
      );
    case TrayMouth.frown:
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s / 2, s * 0.74),
          width: s * 0.32,
          height: s * 0.22,
        ),
        3.66, // mirrored: arc opens upward
        1.96,
        false,
        stroke,
      );
  }
}

/// Flutter hands back straight RGBA; SNI wants ARGB32 in network byte order.
List<int> _rgbaToArgb32(List<int> rgba) {
  final argb = List<int>.filled(rgba.length, 0);
  for (var i = 0; i < rgba.length; i += 4) {
    argb[i] = rgba[i + 3]; // A
    argb[i + 1] = rgba[i]; // R
    argb[i + 2] = rgba[i + 1]; // G
    argb[i + 3] = rgba[i + 2]; // B
  }
  return argb;
}
