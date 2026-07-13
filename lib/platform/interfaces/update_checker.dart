/// Looks up the newest released version.
abstract interface class UpdateChecker {
  /// Latest release version (e.g. "1.2.0"), or null when unavailable.
  /// Must not throw — offline is normal.
  Future<String?> latestVersion();
}
