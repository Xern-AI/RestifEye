/// Controls the app window during breaks.
abstract interface class OverlayController {
  /// Called once at startup (prevent-close-to-background etc.).
  Future<void> init();

  /// Takes over the screen: show, fullscreen, always-on-top, focus.
  /// When [strict], the window re-asserts focus if it loses it.
  Future<void> enterBreak({required bool strict});

  /// Returns the window to its normal state.
  Future<void> exitBreak();
}
