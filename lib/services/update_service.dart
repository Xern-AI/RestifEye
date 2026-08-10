// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import '../app/version.dart';
import '../core/clock.dart';
import '../data/settings_repository.dart';
import '../platform/interfaces/break_notifier.dart';
import '../platform/interfaces/update_checker.dart';

/// Weekly, opt-out update check — the app's only network activity.
class UpdateService {
  UpdateService({
    required this._checker,
    required this._notifier,
    required this._settings,
    required this._clock,
  });

  static const _checkEvery = Duration(days: 7);
  static const _lastCheckKey = 'last_update_check';

  final UpdateChecker _checker;
  final BreakNotifier _notifier;
  final SettingsRepository _settings;
  final Clock _clock;

  /// Call once at startup. Returns the newer version when one was found
  /// and notified, for testability.
  Future<String?> maybeCheck() async {
    final enabled = await _settings.getFlag(
      SettingsRepository.flagUpdateCheck,
      fallback: true,
    );
    if (!enabled) return null;

    final now = _clock.now();
    final lastRaw = await _settings.readValue(_lastCheckKey);
    final last = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    if (last != null && now.difference(last) < _checkEvery) return null;

    await _settings.writeValue(_lastCheckKey, now.toIso8601String());
    final latest = await _checker.latestVersion();
    if (latest == null ||
        !isNewerVersion(current: appVersion, candidate: latest)) {
      return null;
    }
    await _notifier.showInfo(
      title: 'RestifEye $latest is available',
      body: 'You have $appVersion. Get the update from the RestifEye site.',
    );
    return latest;
  }
}
