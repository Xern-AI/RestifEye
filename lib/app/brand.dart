/// Single source of truth for the app's identity.
///
/// The product rename is still pending, and the name was previously hard-coded
/// across the tray item, notifications, window title, desktop entry, AppStream
/// metainfo, RPM spec and the site. Everything in Dart now resolves from here,
/// so renaming is a one-line change plus the packaging files listed in
/// `docs/knowledge_graph.md`.
abstract final class Brand {
  /// Human-readable product name, shown to users.
  static const appName = 'RestifEye';

  /// Reverse-DNS application id. Must match the `.desktop` file's basename,
  /// or the desktop will not attach our icon and name to notifications.
  static const appId = 'com.xernai.restifeye';

  /// Vendor, for the About box and copyright lines.
  static const vendor = 'Xernai';
}
