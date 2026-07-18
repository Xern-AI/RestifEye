// Guards the tray rendering pipeline: every mood must produce well-formed
// ARGB32 pixmaps at both sizes with something actually drawn in them.
//
// The faces themselves were checked by eye during development by rendering a
// contact sheet; see docs/knowledge_graph.md for how to regenerate one.
import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/tray_face.dart';
import 'package:restifeye/core/mood/mood.dart';

void main() {
  test('every mood renders valid pixmaps at both sizes', () async {
    for (final mood in Mood.values) {
      final pixmaps = await renderTrayFace(mood);
      expect(pixmaps.length, 2, reason: '$mood should render 24 and 48 px');
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
