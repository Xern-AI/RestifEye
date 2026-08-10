// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/tray_face.dart';
import 'package:restifeye/core/mood/mood.dart';
import 'package:restifeye/platform/fake/fake_signals.dart';
import 'package:restifeye/services/tray_mood_presenter.dart';

String tooltipOf(Mood mood) => MoodFace.of(mood).tooltip;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeTrayIndicator tray;
  late StreamController<Mood> moods;

  setUp(() {
    tray = FakeTrayIndicator();
    moods = StreamController<Mood>.broadcast();
  });

  tearDown(() => moods.close());

  TrayMoodPresenter presenterFor({
    bool enabled = true,
    Mood initial = Mood.good,
  }) => TrayMoodPresenter(
    tray: tray,
    moods: moods.stream,
    enabled: enabled,
    initial: initial,
  );

  test('starts on the mood the app had already concluded', () async {
    await presenterFor(initial: Mood.slipping).start();

    expect(tray.tooltip, tooltipOf(Mood.slipping));
  });

  test('shows the neutral face when the indicator is switched off', () async {
    final presenter = presenterFor(enabled: false, initial: Mood.ignoring);
    await presenter.start();
    await presenter.show(Mood.tired);

    expect(tray.tooltips, everyElement(tooltipOf(Mood.good)));
  });

  // Each frame renders five sizes with an await apiece, so an update that
  // arrives mid-pulse used to race the one already in flight: whichever
  // finished last won, and the tray could settle on the older mood for
  // however long it took the next real change to arrive.
  test('a mood arriving mid-pulse is the one left on the tray', () async {
    final presenter = presenterFor();
    await presenter.start();

    unawaited(presenter.show(Mood.ignoring));
    await presenter.show(Mood.great);

    expect(tray.tooltip, tooltipOf(Mood.great));
    expect(
      tray.tooltips,
      isNot(contains(tooltipOf(Mood.ignoring))),
      reason: 'a superseded frame is dropped, not written',
    );
  });

  test('moods from the service reach the tray', () async {
    final presenter = presenterFor();
    await presenter.start();

    moods.add(Mood.resting);
    await Future<void>.delayed(const Duration(seconds: 1));

    expect(tray.tooltip, tooltipOf(Mood.resting));
    await presenter.dispose();
  });
}
