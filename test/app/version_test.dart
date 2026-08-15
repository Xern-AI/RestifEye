// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:restifeye/app/version.dart';

/// Writes a bundle laid out the way `flutter build linux` lays one out, and
/// returns the path the executable would have inside it.
String _bundle(Directory root, String versionJson) {
  Directory('${root.path}/data/flutter_assets').createSync(recursive: true);
  File(
    '${root.path}/data/flutter_assets/version.json',
  ).writeAsStringSync(versionJson);
  return '${root.path}/RestifEye';
}

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('RestifEye_version_'));
  tearDown(() => tmp.delete(recursive: true));

  // Ordered: every case after the first asserts against the value the
  // previous one left behind, which is the whole point of a fallback.
  test('reports a placeholder until the bundle has been read', () {
    expect(appVersion, '0.0.0');
    expect(appBuild, isNull);
  });

  test('a missing bundle leaves the current value untouched', () async {
    await loadAppVersion(executablePath: '${tmp.path}/RestifEye');
    expect(appVersion, '0.0.0');
  });

  test('reads the version and build number pubspec produced', () async {
    final exe = _bundle(
      tmp,
      '{"app_name":"restifeye","version":"1.2.3","build_number":"7",'
      '"package_name":"restifeye"}',
    );
    await loadAppVersion(executablePath: exe);
    expect(appVersion, '1.2.3');
    expect(appBuild, '7');
  });

  test('malformed json keeps the last good value', () async {
    final exe = _bundle(tmp, 'not json at all');
    await loadAppVersion(executablePath: exe);
    expect(appVersion, '1.2.3');
  });

  test('a bundle without a version field keeps the last good value', () async {
    final exe = _bundle(tmp, '{"app_name":"restifeye"}');
    await loadAppVersion(executablePath: exe);
    expect(appVersion, '1.2.3');
  });

  group('isNewerVersion', () {
    test('compares semver, tolerating a leading v and build suffixes', () {
      expect(isNewerVersion(current: '0.1.4', candidate: 'v0.1.5'), isTrue);
      expect(isNewerVersion(current: '0.1.4', candidate: '0.2.0+9'), isTrue);
      expect(isNewerVersion(current: '0.1.4', candidate: '0.1.4'), isFalse);
      expect(isNewerVersion(current: '0.1.4', candidate: '0.1.3'), isFalse);
      expect(isNewerVersion(current: '0.1.4', candidate: '1'), isTrue);
    });

    test('treats garbage as not newer', () {
      expect(isNewerVersion(current: '0.1.4', candidate: 'latest'), isFalse);
      expect(isNewerVersion(current: 'nightly', candidate: '9.9.9'), isFalse);
    });
  });
}
