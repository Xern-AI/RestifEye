/// Launch-at-login control.
abstract interface class Autostart {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}
