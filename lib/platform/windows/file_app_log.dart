// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

import '../interfaces/app_log.dart';

/// One file per local day (`restifeye-YYYY-MM-DD.log`), newest [keepDays]
/// kept.
///
/// Each line is appended and closed straight away rather than buffered: the
/// log exists for the bug reports where the app died, and a buffer is exactly
/// what a crash loses. The volume is a few lines per break, so the cost of
/// reopening the file is irrelevant.
class FileAppLog implements AppLog {
  FileAppLog(this.directory, {DateTime Function()? now, this.keepDays = 7})
    : _now = now ?? DateTime.now;

  final Directory directory;
  final int keepDays;
  final DateTime Function() _now;

  String? _pruned;

  @override
  bool get enabled => true;

  @override
  void info(String message) => _write('INFO ', message);

  @override
  void failure(String adapter, Object error) =>
      _write('FAIL ', '$adapter: ${_oneLine(error)}');

  @override
  void error(Object error, StackTrace? stack) {
    final trace = stack == null ? '' : '\n$stack'.trimRight();
    _write('ERROR', '${_oneLine(error)}$trace');
  }

  static String fileNameFor(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'restifeye-${day.year}-${two(day.month)}-${two(day.day)}.log';
  }

  void _write(String tag, String message) {
    final now = _now();
    final name = fileNameFor(now);
    try {
      directory.createSync(recursive: true);
      File(p.join(directory.path, name)).writeAsStringSync(
        '${now.toIso8601String()} $tag $message\n',
        mode: FileMode.append,
        flush: true,
      );
      if (_pruned != name) {
        _pruned = name;
        _prune();
      }
    } on FileSystemException {
      // A log that cannot be written must never take the app down with it.
    }
  }

  void _prune() {
    final logs =
        directory
            .listSync()
            .whereType<File>()
            .where(
              (f) => RegExp(
                r'^restifeye-\d{4}-\d{2}-\d{2}\.log$',
              ).hasMatch(p.basename(f.path)),
            )
            .toList()
          ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final old in logs.skip(keepDays)) {
      old.deleteSync();
    }
  }

  static String _oneLine(Object error) =>
      error.toString().replaceAll(RegExp(r'\s*\n\s*'), ' | ');
}
