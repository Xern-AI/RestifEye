import 'package:breaktime/core/models/activity.dart';
import 'package:breaktime/services/activity_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<ActivitySlice> sink;
  late ActivityRecorder recorder;
  final t0 = DateTime(2026, 7, 10, 9);

  setUp(() {
    sink = [];
    recorder = ActivityRecorder((slice) async => sink.add(slice));
  });

  test('emits a slice when the activity kind changes', () {
    recorder.observe(t0, SliceKind.active);
    recorder.observe(t0.add(const Duration(minutes: 10)), SliceKind.active);
    recorder.observe(t0.add(const Duration(minutes: 20)), SliceKind.idle);

    expect(sink, hasLength(1));
    expect(sink.single.kind, SliceKind.active);
    expect(sink.single.length, const Duration(minutes: 20));
  });

  test('flush persists the open slice and continues it', () async {
    recorder.observe(t0, SliceKind.active);
    await recorder.flush(t0.add(const Duration(minutes: 5)));
    recorder.observe(t0.add(const Duration(minutes: 8)), SliceKind.locked);

    expect(sink, hasLength(2));
    expect(sink[0].length, const Duration(minutes: 5));
    expect(sink[1].start, t0.add(const Duration(minutes: 5)));
    expect(sink[1].length, const Duration(minutes: 3));
  });

  test('sub-second slices are dropped as noise', () {
    recorder.observe(t0, SliceKind.active);
    recorder.observe(t0.add(const Duration(milliseconds: 400)), SliceKind.idle);
    expect(sink, isEmpty);
  });
}
