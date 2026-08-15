// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Used until [loadAppVersion] runs, and if it ever fails. Deliberately
/// lower than any real release so a broken read can only ever under-report,
/// never suppress an update notification.
const _unknownVersion = '0.0.0';

String _appVersion = _unknownVersion;
String? _appBuild;

/// The running build's version, e.g. `0.1.4`.
///
/// Sourced from `pubspec.yaml` — Flutter writes it into the bundle as
/// `version.json` on every build, so bumping pubspec is the only step needed
/// to change what the app reports and displays. It was previously a hand-kept
/// constant, which drifted to `0.1.0` while releases were at `0.1.3` and made
/// the update check compare against a version that had never shipped.
String get appVersion => _appVersion;

/// The build number after the `+` in pubspec, e.g. `5`. Null when unknown.
String? get appBuild => _appBuild;

/// GitHub repo used by the update check (and the site links).
const githubRepoSlug = 'Xern-AI/restifeye';

/// Reads the version Flutter generated from `pubspec.yaml` into the bundle.
///
/// Read from disk rather than through `rootBundle` because `version.json` is
/// not an entry in the asset manifest — it is written beside the assets. This
/// is the same path `package_info_plus` uses on Linux, and it resolves
/// correctly inside an AppImage, where the executable lives on the mount.
///
/// Never throws: a build with no readable `version.json` still starts, it just
/// reports [_unknownVersion].
Future<void> loadAppVersion({String? executablePath}) async {
  try {
    final file = File(
      p.join(
        p.dirname(executablePath ?? Platform.resolvedExecutable),
        'data',
        'flutter_assets',
        'version.json',
      ),
    );
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return;

    final version = decoded['version'];
    if (version is String && version.isNotEmpty) _appVersion = version;

    final build = decoded['build_number'];
    if (build is String && build.isNotEmpty) _appBuild = build;
  } on Exception {
    // Missing, unreadable or malformed — the fallback already applies.
  }
}

/// True when [candidate] is a strictly newer semver than [current].
/// Tolerates a leading 'v' and missing segments; returns false on garbage.
bool isNewerVersion({required String current, required String candidate}) {
  List<int>? parse(String v) {
    final cleaned = v.trim().replaceFirst(RegExp('^v'), '');
    final core = cleaned.split(RegExp('[+-]')).first;
    final parts = core.split('.');
    final numbers = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null) return null;
      numbers.add(n);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return numbers;
  }

  final a = parse(current);
  final b = parse(candidate);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (b[i] > a[i]) return true;
    if (b[i] < a[i]) return false;
  }
  return false;
}
