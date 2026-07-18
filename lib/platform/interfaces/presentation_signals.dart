/// Whether something on screen must not be interrupted right now.
class PresentationState {
  const PresentationState({required this.active, this.byApp});

  /// Nothing is claiming the screen.
  static const idle = PresentationState(active: false);

  /// True while a fullscreen video, presentation, or game is running.
  final bool active;

  /// The app responsible, when the desktop names it (e.g. `mpv`, `Firefox`).
  /// Null is the normal degraded case, not an error.
  final String? byApp;

  @override
  bool operator ==(Object other) =>
      other is PresentationState &&
      other.active == active &&
      other.byApp == byApp;

  @override
  int get hashCode => Object.hash(active, byApp);
}

/// Detects "do not interrupt me, I'm watching something".
///
/// Deliberately built on **idle inhibitors** rather than audio playback.
/// Video players, browsers in fullscreen video, presentation tools and games
/// all take an idle inhibitor so the screen never blanks on them; music
/// players do not. Keying off raw audio instead would let a background
/// playlist suppress breaks for an entire working day.
abstract interface class PresentationSignals {
  /// Implementations must return [PresentationState.idle] on backend errors
  /// — never throw. Failing open means breaks keep working, which is the
  /// safe direction for a health app.
  Future<PresentationState> sample();
}
