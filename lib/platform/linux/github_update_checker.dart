// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import '../../app/version.dart';
import '../interfaces/update_checker.dart';

/// Latest release tag from the public GitHub API. The app's only network
/// call, and it can be disabled in Settings.
class GithubUpdateChecker implements UpdateChecker {
  GithubUpdateChecker({String repoSlug = githubRepoSlug})
    : _url = Uri.https('api.github.com', '/repos/$repoSlug/releases/latest');

  final Uri _url;

  @override
  Future<String?> latestVersion() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(_url);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      request.headers.set(HttpHeaders.userAgentHeader, 'RestifEye/$appVersion');
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final tag = (jsonDecode(body) as Map<String, Object?>)['tag_name'];
      return tag is String ? tag.replaceFirst(RegExp('^v'), '') : null;
    } on Exception {
      return null; // offline, rate-limited, repo missing — all fine
    } finally {
      client.close(force: true);
    }
  }
}
