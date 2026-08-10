// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

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

/// A percentage with no decimals: "81%".
String formatPercent(double fraction) => '${(fraction * 100).round()}%';

/// Minutes since local midnight as a 24-hour clock time: "09:14".
String formatMinuteOfDay(int minuteOfDay) {
  final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
