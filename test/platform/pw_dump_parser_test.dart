import 'package:breaktime/platform/linux/pw_dump_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _runningMicCapture = '''
[
  {"id": 30, "type": "PipeWire:Interface:Device", "info": {"props": {}}},
  {
    "id": 55,
    "type": "PipeWire:Interface:Node",
    "info": {
      "state": "running",
      "props": {
        "media.class": "Stream/Input/Audio",
        "application.name": "Firefox"
      }
    }
  }
]
''';

const _idleSystem = '''
[
  {
    "id": 55,
    "type": "PipeWire:Interface:Node",
    "info": {
      "state": "suspended",
      "props": {"media.class": "Stream/Input/Audio"}
    }
  },
  {
    "id": 60,
    "type": "PipeWire:Interface:Node",
    "info": {
      "state": "running",
      "props": {"media.class": "Stream/Output/Audio"}
    }
  }
]
''';

void main() {
  test('detects a running mic capture stream', () {
    expect(pwDumpShowsCapture(_runningMicCapture), isTrue);
  });

  test('ignores suspended captures and output streams (music playing)', () {
    expect(pwDumpShowsCapture(_idleSystem), isFalse);
  });

  test('detects a running camera stream', () {
    final json = _runningMicCapture.replaceFirst(
      'Stream/Input/Audio',
      'Stream/Input/Video',
    );
    expect(pwDumpShowsCapture(json), isTrue);
  });

  test('is robust to malformed output', () {
    expect(pwDumpShowsCapture('not json'), isFalse);
    expect(pwDumpShowsCapture('{}'), isFalse);
    expect(pwDumpShowsCapture('[]'), isFalse);
    expect(
      pwDumpShowsCapture('[{"type": "PipeWire:Interface:Node"}]'),
      isFalse,
    );
  });
}
