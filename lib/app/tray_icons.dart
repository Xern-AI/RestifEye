import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../platform/interfaces/tray_indicator.dart';

/// Decodes the bundled tray PNGs into the ARGB32 pixmaps the
/// StatusNotifierItem protocol expects (network byte order).
Future<List<TrayPixmap>> loadTrayPixmaps() async {
  const paths = ['assets/icons/tray_24.png', 'assets/icons/tray_48.png'];
  final pixmaps = <TrayPixmap>[];
  for (final path in paths) {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (rgba == null) continue;
    final bytes = rgba.buffer.asUint8List();
    final argb = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 4) {
      argb[i] = bytes[i + 3]; // A
      argb[i + 1] = bytes[i]; // R
      argb[i + 2] = bytes[i + 1]; // G
      argb[i + 3] = bytes[i + 2]; // B
    }
    pixmaps.add(
      TrayPixmap(width: image.width, height: image.height, argb32: argb),
    );
    image.dispose();
  }
  return pixmaps;
}
