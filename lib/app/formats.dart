/// Human-friendly duration strings, shared across screens.
String formatCountdown(Duration d) {
  final clamped = d.isNegative ? Duration.zero : d;
  final minutes = clamped.inMinutes;
  final seconds = clamped.inSeconds % 60;
  if (clamped.inHours > 0) {
    final h = clamped.inHours;
    final m = minutes % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatHoursMinutes(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}
