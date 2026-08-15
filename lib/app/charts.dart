// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../core/models/activity.dart';

/// The four states a minute of the day can be in, ordered by how engaged the
/// person was: hands on the keyboard, watching something, at the desk but
/// idle, then gone.
///
/// The order is the whole point. Because these are ranked rather than merely
/// different, they are coloured as a **sequential ramp of one hue** — solid
/// for active, fading to nearly transparent for away — instead of four
/// competing hues. That is honest about the ordering, needs no
/// colour-blindness trade-offs at all, and follows the theme into dark mode
/// without a second palette to keep in sync.
/// The palest step stops well short of transparent: a band that fades into
/// the card reads as missing data rather than as time spent away.
enum ActivityBand {
  active('Active', 'Typing and clicking', 1),
  watching('Watching', 'Video, calls or slides', 0.7),
  idle('Idle', 'Here, but hands off', 0.46),
  away('Away', 'Locked or suspended', 0.28);

  const ActivityBand(this.label, this.description, this.weight);

  final String label;
  final String description;

  /// Opacity of the primary hue. Monotonic by construction, so the ramp can
  /// never come out unordered.
  final double weight;

  Color color(ColorScheme scheme) => scheme.primary.withValues(alpha: weight);

  int secondsIn(HourBand hour) => switch (this) {
    ActivityBand.active => hour.active,
    ActivityBand.watching => hour.watching,
    ActivityBand.idle => hour.idle,
    ActivityBand.away => hour.away,
  };
}

/// Total seconds recorded in an hour, across every band.
int hourTotal(HourBand hour) =>
    hour.active + hour.watching + hour.idle + hour.away;
