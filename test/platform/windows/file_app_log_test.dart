// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:restifeye/platform/windows/file_app_log.dart';

void main() {
  late Directory tmp;
  var now = DateTime(2026, 10, 22, 9, 30);

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('restifeye_log_');
    now = DateTime(2026, 10, 22, 9, 30);
  });

  tearDown(() => tmp.delete(recursive: true));

  FileAppLog logIn(Directory dir) => FileAppLog(dir, now: () => now);

  String read(String name) => File(p.join(tmp.path, name)).readAsStringSync();

  test('writes tagged lines into the file for the local day', () {
    final log = logIn(tmp)
      ..info('startup')
      ..failure('idle', StateError('no input info'))
      ..error(Exception('boom\nsecond line'), null);

    expect(log.enabled, isTrue);
    final lines = read('restifeye-2026-10-22.log').trim().split('\n');
    expect(lines, hasLength(3));
    expect(lines[0], endsWith(' INFO  startup'));
    expect(lines[1], contains(' FAIL  idle: Bad state: no input info'));
    expect(lines[2], contains(' ERROR Exception: boom | second line'));
  });

  test('a new day starts a new file', () {
    final log = logIn(tmp)..info('one');
    now = DateTime(2026, 10, 23, 0, 1);
    log.info('two');

    expect(read('restifeye-2026-10-22.log'), contains('one'));
    expect(read('restifeye-2026-10-23.log'), contains('two'));
  });

  test('keeps only the newest seven day files and ignores other files', () {
    for (var day = 1; day <= 9; day++) {
      File(
        p.join(tmp.path, FileAppLog.fileNameFor(DateTime(2026, 10, day))),
      ).writeAsStringSync('old\n');
    }
    File(p.join(tmp.path, 'notes.txt')).writeAsStringSync('keep me');

    logIn(tmp).info('today');

    final names = tmp.listSync().map((f) => p.basename(f.path)).toSet();
    expect(names, contains('notes.txt'));
    expect(names, contains('restifeye-2026-10-22.log'));
    expect(names, contains('restifeye-2026-10-04.log'));
    expect(names, isNot(contains('restifeye-2026-10-03.log')));
    expect(names.where((n) => n.endsWith('.log')), hasLength(7));
  });

  test('creates the directory and never throws when it cannot write', () {
    final nested = Directory(p.join(tmp.path, 'a', 'logs'));
    logIn(nested).info('hello');
    expect(nested.existsSync(), isTrue);

    final blocker = File(p.join(tmp.path, 'blocked'))..writeAsStringSync('x');
    expect(() => logIn(Directory(blocker.path)).info('lost'), returnsNormally);
  });
}
