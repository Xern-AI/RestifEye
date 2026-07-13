/// Controls the app window during breaks.
abstract interface class OverlayController {
  /// Called once at startup (prevent-close-to-background etc.).
  Future<void> init();

  /// Brings the break on screen. With [fullscreen], the window seizes the
  /// whole screen and stays on top; otherwise it surfaces as a normal
  /// window. When [strict], the window re-asserts focus if it loses it.
  Future<void> enterBreak({required bool strict, required bool fullscreen});

  /// Returns the window to its normal state.
  Future<void> exitBreak();
}
