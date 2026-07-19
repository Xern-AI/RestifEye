// Guards the tray rendering pipeline: every mood must produce well-formed
// ARGB32 pixmaps at both sizes with something actually drawn in them.
//
// The faces themselves were checked by eye during development by rendering a
// contact sheet; see docs/knowledge_graph.md for how to regenerate one.
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/tray_face.dart';
import 'package:restifeye/core/mood/mood.dart';

void main() {
  test('offers no size too small to render the face legibly', () async {
    final pixmaps = await renderTrayFace(Mood.good);
    expect(
      pixmaps.map((p) => p.width),
      everyElement(greaterThanOrEqualTo(22)),
      reason:
          'below 22 px the strokes fall under a pixel; a host that takes '
          'the first entry rather than the best fit would draw mush',
    );
    expect(pixmaps.length, greaterThan(2));
  });

  test('the face very nearly fills the pixmap', () async {
    // Regression: the tray face inherited the launcher icon's 6.25% margin,
    // which the panel then padded again — the icon rendered visibly smaller
    // than every other status icon.
    final p = (await renderTrayFace(
      Mood.good,
    )).firstWhere((p) => p.width == 48);
    int alphaAt(int x, int y) => p.argb32[(y * p.width + x) * 4];
    final mid = p.height ~/ 2;
    expect(
      alphaAt(2, mid),
      greaterThan(0),
      reason: 'two pixels in from the edge should already be inside the face',
    );
  });

  test('every mood renders valid pixmaps at every offered size', () async {
    for (final mood in Mood.values) {
      final pixmaps = await renderTrayFace(mood);
      expect(pixmaps, isNotEmpty, reason: '$mood rendered nothing');
      for (final p in pixmaps) {
        expect(p.argb32.length, p.width * p.height * 4);
        // A face must actually be drawn: some pixel has to be opaque.
        expect(
          p.argb32.asMap().entries.any((e) => e.key % 4 == 0 && e.value > 0),
          isTrue,
          reason: '$mood at ${p.width}px rendered fully transparent',
        );
      }
    }
  });
}
