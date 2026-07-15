/// What the user chose from the tray icon or its menu.
enum TrayAction { open, togglePause, quit }

/// One rasterized icon size, ARGB32 in network byte order (SNI wire format).
class TrayPixmap {
  const TrayPixmap({
    required this.width,
    required this.height,
    required this.argb32,
  });

  final int width;
  final int height;
  final List<int> argb32;
}

/// A persistent "RestifEye is running" indicator in the system tray /
/// status area, with a minimal menu (open, pause, quit).
abstract interface class TrayIndicator {
  /// Registers the indicator. Safe to call on desktops without a status
  /// area — the indicator simply stays invisible until a host appears.
  Future<void> init({required List<TrayPixmap> icons});

  /// Reflects the engine's paused state in the menu.
  Future<void> setPaused(bool paused);

  /// Menu selections and icon activations.
  Stream<TrayAction> get actions;

  Future<void> dispose();
}
